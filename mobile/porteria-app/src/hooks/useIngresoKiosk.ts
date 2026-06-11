import { useCallback, useEffect, useRef, useState } from 'react';
import { puertasParaModo } from '../lib/puertaLabels';
import { Alert } from 'react-native';
import { consultarIngreso, registrarIngreso } from '../api/client';
import { parseCapturaDocumento, normalizeDocumento } from '../lib/pdf417';
import { getEntradaDefault } from '../lib/storage';
import { queueIngreso, runSync } from '../sync/SyncEngine';
import { cerrarLocalAcceso } from '../db/schema';
import type { Catalogos, IngresoAbierto, IngresoPayload, Persona } from '../types';

export type KioskStep = 'documento' | 'confirmacion' | 'datos' | 'puerta';

export type KioskFlow = 'known' | 'new';

const MIN_DIGITS = 5;
const MAX_DIGITS = 10;
const PREFETCH_MS = 120;

type ConsultData = {
  persona: Persona | null;
  puede_ingresar: boolean;
  ingreso_abierto: IngresoAbierto | null;
};

type UseIngresoKioskParams = {
  catalogos: Catalogos | null;
  online: boolean;
};

export function useIngresoKiosk({ catalogos, online }: UseIngresoKioskParams) {
  const [step, setStep] = useState<KioskStep>('documento');
  const [flow, setFlow] = useState<KioskFlow | null>(null);
  const [documento, setDocumento] = useState('');
  const [tipoDoc, setTipoDoc] = useState('CC');
  const [capturaRaw, setCapturaRaw] = useState('');
  const [metodoAut, setMetodoAut] = useState(1);
  const [nombres, setNombres] = useState('');
  const [apellidos, setApellidos] = useState('');
  const [tipoPersona, setTipoPersona] = useState(0);
  const [idEntrada, setIdEntrada] = useState(0);
  const [puertaTouched, setPuertaTouched] = useState(false);
  const [persona, setPersona] = useState<Persona | null>(null);
  const [puedeIngresar, setPuedeIngresar] = useState(true);
  const [consultLoading, setConsultLoading] = useState(false);
  const [busy, setBusy] = useState(false);

  const fetchResultRef = useRef<ConsultData | null>(null);
  const fetchPromiseRef = useRef<Promise<ConsultData | null> | null>(null);
  const prefetchTimerRef = useRef<ReturnType<typeof setTimeout> | null>(null);

  useEffect(() => {
    void getEntradaDefault().then((d) => {
      if (d) setIdEntrada(d);
    });
  }, []);

  const clearPrefetch = useCallback(() => {
    if (prefetchTimerRef.current) {
      clearTimeout(prefetchTimerRef.current);
      prefetchTimerRef.current = null;
    }
    fetchResultRef.current = null;
    fetchPromiseRef.current = null;
  }, []);

  const runConsult = useCallback(
    async (doc: string): Promise<ConsultData | null> => {
      if (!online || doc.length < MIN_DIGITS) {
        return null;
      }
      const res = await consultarIngreso(doc, tipoDoc);
      if (!res.ok) {
        return null;
      }
      if (res.data.puede_ingresar) {
        await cerrarLocalAcceso(tipoDoc, doc);
      }
      const data: ConsultData = {
        persona: (res.data.persona as Persona | null) ?? null,
        puede_ingresar: res.data.puede_ingresar,
        ingreso_abierto: (res.data.ingreso_abierto as IngresoAbierto | null) ?? null,
      };
      return data;
    },
    [online, tipoDoc]
  );

  const schedulePrefetch = useCallback(
    (doc: string) => {
      clearPrefetch();
      if (doc.length < MIN_DIGITS) return;

      prefetchTimerRef.current = setTimeout(() => {
        const promise = runConsult(doc).then((data) => {
          fetchResultRef.current = data;
          return data;
        });
        fetchPromiseRef.current = promise;
      }, PREFETCH_MS);
    },
    [clearPrefetch, runConsult]
  );

  const applyConsult = useCallback((data: ConsultData | null) => {
    if (!data) {
      setPersona(null);
      setPuedeIngresar(false);
      setFlow(null);
      return;
    }

    setPuedeIngresar(data.puede_ingresar);
    if (data.persona?.nombres?.trim()) {
      setPersona(data.persona);
      setNombres(data.persona.nombres);
      setApellidos(data.persona.apellidos);
      if (data.persona.tipo_persona) setTipoPersona(data.persona.tipo_persona);
      setFlow('known');
    } else if (data.ingreso_abierto) {
      setPersona(null);
      setFlow('known');
    } else {
      setPersona(null);
      setFlow('new');
    }
  }, []);

  const updateDocumento = useCallback(
    (digits: string) => {
      const next = digits.slice(0, MAX_DIGITS);
      setDocumento(next);
      schedulePrefetch(next);
    },
    [schedulePrefetch]
  );

  const appendDigit = useCallback(
    (d: string) => {
      if (documento.length >= MAX_DIGITS) return;
      updateDocumento(documento + d);
    },
    [documento, updateDocumento]
  );

  const deleteDigit = useCallback(() => {
    const next = documento.slice(0, -1);
    setDocumento(next);
    if (next.length < MIN_DIGITS) {
      clearPrefetch();
    } else {
      schedulePrefetch(next);
    }
  }, [documento, clearPrefetch, schedulePrefetch]);

  const reset = useCallback(() => {
    clearPrefetch();
    setStep('documento');
    setFlow(null);
    setDocumento('');
    setTipoDoc('CC');
    setCapturaRaw('');
    setMetodoAut(1);
    setNombres('');
    setApellidos('');
    setTipoPersona(0);
    setPuertaTouched(false);
    setPersona(null);
    setPuedeIngresar(true);
    setConsultLoading(false);
    void getEntradaDefault().then((d) => {
      if (d) setIdEntrada(d);
      else setIdEntrada(0);
    });
  }, [clearPrefetch]);

  const applyScan = useCallback(
    async (raw: string) => {
      const parsed = parseCapturaDocumento(raw);
      setCapturaRaw(parsed.captura_raw);
      setTipoDoc(parsed.tipo_doc);
      setMetodoAut(parsed.metodo_aut);
      if (parsed.nombres) setNombres(parsed.nombres);
      if (parsed.apellidos) setApellidos(parsed.apellidos);
      updateDocumento(parsed.documento);

      if (!parsed.documento || parsed.documento.length < MIN_DIGITS) return;

      setConsultLoading(true);
      setStep('confirmacion');
      try {
        const data = await runConsult(parsed.documento);
        fetchResultRef.current = data;
        applyConsult(data);
      } finally {
        setConsultLoading(false);
      }
    },
    [applyConsult, runConsult, updateDocumento]
  );

  const continueFromDocumento = useCallback(async () => {
    if (documento.length < MIN_DIGITS) return;

    setConsultLoading(true);
    setStep('confirmacion');

    try {
      let data = fetchResultRef.current;
      if (!data && fetchPromiseRef.current) {
        data = await fetchPromiseRef.current;
      }
      if (!data) {
        data = await runConsult(documento);
        fetchResultRef.current = data;
      }
      applyConsult(data);
    } finally {
      setConsultLoading(false);
    }
  }, [documento, applyConsult, runConsult]);

  const correct = useCallback(() => {
    reset();
  }, [reset]);

  const goBack = useCallback(() => {
    if (busy) return;
    switch (step) {
      case 'puerta':
        setStep(flow === 'new' ? 'datos' : 'confirmacion');
        break;
      case 'datos':
        setStep('confirmacion');
        break;
      case 'confirmacion':
        setConsultLoading(false);
        setStep('documento');
        break;
      default:
        break;
    }
  }, [step, flow, busy]);

  const confirmKnown = useCallback(() => {
    if (!puedeIngresar) return;
    setFlow('known');
    setStep('puerta');
    if (idEntrada > 0) {
      setPuertaTouched(true);
    }
  }, [puedeIngresar, idEntrada]);

  const continueNewFromAviso = useCallback(() => {
    setFlow('new');
    setStep('datos');
  }, []);

  const continueFromDatos = useCallback(() => {
    if (nombres.trim().length < 2) {
      Alert.alert('Nombre', 'Indique los nombres.');
      return;
    }
    if (apellidos.trim().length < 2) {
      Alert.alert('Apellidos', 'Indique los apellidos.');
      return;
    }
    if (!tipoPersona) {
      Alert.alert('Tipo persona', 'Seleccione el tipo de persona.');
      return;
    }
    setStep('puerta');
    if (idEntrada > 0) {
      setPuertaTouched(true);
    }
  }, [nombres, apellidos, tipoPersona, idEntrada]);

  const selectPuerta = useCallback((id: number) => {
    setIdEntrada(id);
    setPuertaTouched(true);
  }, []);

  const confirmRegister = useCallback(async () => {
    const doc = normalizeDocumento(documento);
    if (!doc) {
      Alert.alert('Documento', 'Indique el número de documento.');
      return;
    }
    if (!puertaTouched || !idEntrada) {
      Alert.alert('Puerta', 'Seleccione la puerta de ingreso.');
      return;
    }
    if (!tipoPersona) {
      Alert.alert('Tipo persona', 'Seleccione el tipo de persona.');
      return;
    }
    if (nombres.trim().length < 2 || apellidos.trim().length < 2) {
      Alert.alert('Nombre', 'Indique nombres y apellidos.');
      return;
    }

    setBusy(true);
    try {
      const payload: IngresoPayload = {
        tipo_doc: tipoDoc,
        documento: doc,
        captura_raw: capturaRaw,
        tipo_persona: tipoPersona,
        nombres: nombres.trim().toUpperCase(),
        apellidos: apellidos.trim().toUpperCase(),
        id_entrada: idEntrada,
        metodo_aut: metodoAut,
      };

      if (online) {
        const res = await registrarIngreso(payload as unknown as Record<string, unknown>);
        if (!res.ok) {
          Alert.alert('Error', res.error);
          return;
        }
        Alert.alert('Ingreso registrado', `#${res.data.id_ingreso}`);
      } else {
        await queueIngreso(payload, null);
        Alert.alert('Guardado local', 'Se sincronizará cuando vuelva la conexión.');
      }

      reset();
      void runSync();
    } finally {
      setBusy(false);
    }
  }, [
    documento,
    puertaTouched,
    idEntrada,
    tipoPersona,
    nombres,
    apellidos,
    tipoDoc,
    capturaRaw,
    metodoAut,
    online,
    reset,
  ]);

  const canContinueDocumento = documento.length >= MIN_DIGITS;
  const canConfirmPuerta = puertaTouched && idEntrada > 0 && !busy;
  const canGoBack = step !== 'documento' && !busy && !consultLoading;

  const puertas = puertasParaModo(catalogos?.entradas ?? [], 'ingreso');

  return {
    step,
    flow,
    documento,
    nombres,
    apellidos,
    tipoPersona,
    idEntrada,
    persona,
    puedeIngresar,
    consultLoading,
    busy,
    puertas,
    tiposPersona: catalogos?.tipos_persona ?? [],
    canContinueDocumento,
    canConfirmPuerta,
    setNombres,
    setApellidos,
    setTipoPersona,
    appendDigit,
    deleteDigit,
    applyScan,
    continueFromDocumento,
    correct,
    goBack,
    canGoBack,
    confirmKnown,
    continueNewFromAviso,
    continueFromDatos,
    selectPuerta,
    confirmRegister,
    reset,
  };
}
