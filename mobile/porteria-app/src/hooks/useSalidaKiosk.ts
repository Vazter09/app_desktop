import { useCallback, useEffect, useMemo, useRef, useState } from 'react';
import { puertasParaModo } from '../lib/puertaLabels';
import { Alert } from 'react-native';
import { consultarSalida, registrarSalida } from '../api/client';
import { getLocalAccesoAbierto } from '../db/schema';
import { parseCapturaDocumento, normalizeDocumento } from '../lib/pdf417';
import { getEntradaDefault } from '../lib/storage';
import { queueSalida, runSync } from '../sync/SyncEngine';
import type { Catalogos, IngresoAbierto, Persona, SalidaPayload } from '../types';

export type SalidaKioskStep = 'documento' | 'confirmacion' | 'puerta';

const MIN_DIGITS = 5;
const MAX_DIGITS = 10;
const PREFETCH_MS = 120;

type ConsultData = {
  persona: Persona | null;
  puede_salir: boolean;
  ingreso_abierto: IngresoAbierto | null;
  ingreso_client_id: string | null;
};

type UseSalidaKioskParams = {
  catalogos: Catalogos | null;
  online: boolean;
};

export function useSalidaKiosk({ catalogos, online }: UseSalidaKioskParams) {
  const [step, setStep] = useState<SalidaKioskStep>('documento');
  const [puedeSalir, setPuedeSalir] = useState(false);
  const [documento, setDocumento] = useState('');
  const [tipoDoc, setTipoDoc] = useState('CC');
  const [capturaRaw, setCapturaRaw] = useState('');
  const [metodoAut, setMetodoAut] = useState(1);
  const [idEntrada, setIdEntrada] = useState(0);
  const [puertaTouched, setPuertaTouched] = useState(false);
  const [persona, setPersona] = useState<Persona | null>(null);
  const [ingresoAbierto, setIngresoAbierto] = useState<IngresoAbierto | null>(null);
  const [ingresoClientId, setIngresoClientId] = useState<string | null>(null);
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

  const runConsultOnline = useCallback(async (doc: string): Promise<ConsultData | null> => {
    const res = await consultarSalida(doc, 'CC');
    if (!res.ok) return null;
    return {
      persona: (res.data.persona as Persona | null) ?? null,
      puede_salir: res.data.puede_salir,
      ingreso_abierto: (res.data.ingreso_abierto as IngresoAbierto | null) ?? null,
      ingreso_client_id: null,
    };
  }, []);

  const runConsultOffline = useCallback(async (doc: string): Promise<ConsultData | null> => {
    const local = await getLocalAccesoAbierto('CC', doc);
    if (!local) return null;
    return {
      persona: null,
      puede_salir: true,
      ingreso_abierto: {
        id_ingreso: 0,
        fec_ingreso: local.fec_local,
        id_entrada: local.id_entrada,
        nom_entrada: '',
        tipo_persona: 0,
        nom_tipo_persona: 'Local',
        nombres: local.nombres,
        apellidos: local.apellidos,
      },
      ingreso_client_id: local.ingreso_client_id,
    };
  }, []);

  const runConsult = useCallback(
    async (doc: string): Promise<ConsultData | null> => {
      if (doc.length < MIN_DIGITS) return null;
      if (online) return runConsultOnline(doc);
      return runConsultOffline(doc);
    },
    [online, runConsultOnline, runConsultOffline]
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
    if (!data || !data.puede_salir || (!data.persona && !data.ingreso_abierto)) {
      setPuedeSalir(false);
      setPersona(null);
      setIngresoAbierto(null);
      setIngresoClientId(null);
      return;
    }

    setPuedeSalir(true);
    setPersona(data.persona);
    setIngresoAbierto(data.ingreso_abierto);
    setIngresoClientId(data.ingreso_client_id);
    if (data.ingreso_abierto?.id_entrada) {
      setIdEntrada(data.ingreso_abierto.id_entrada);
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
    setPuedeSalir(false);
    setDocumento('');
    setTipoDoc('CC');
    setCapturaRaw('');
    setMetodoAut(1);
    setPuertaTouched(false);
    setPersona(null);
    setIngresoAbierto(null);
    setIngresoClientId(null);
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
        setStep('confirmacion');
        break;
      case 'confirmacion':
        setConsultLoading(false);
        setStep('documento');
        break;
      default:
        break;
    }
  }, [step, busy]);

  const confirmIdentity = useCallback(() => {
    if (!puedeSalir) return;
    setStep('puerta');
    if (idEntrada > 0) {
      setPuertaTouched(true);
    }
  }, [puedeSalir, idEntrada]);

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
    if (!puedeSalir) {
      Alert.alert('Egreso', 'No hay ingreso activo para registrar egreso.');
      return;
    }
    if (!puertaTouched || !idEntrada) {
      Alert.alert('Puerta', 'Seleccione la puerta de egreso.');
      return;
    }

    setBusy(true);
    try {
      const payload: SalidaPayload = {
        tipo_doc: tipoDoc,
        documento: doc,
        captura_raw: capturaRaw,
        metodo_aut: metodoAut,
      };

      if (online) {
        const res = await registrarSalida(payload as unknown as Record<string, unknown>);
        if (!res.ok) {
          Alert.alert('Error', res.error);
          return;
        }
        Alert.alert('Egreso registrado', `#${res.data.id_ingreso}`);
      } else {
        if (!ingresoClientId) {
          Alert.alert('Offline', 'No hay ingreso activo conocido en esta tablet.');
          return;
        }
        await queueSalida(payload, null, ingresoClientId);
        Alert.alert('Guardado local', 'Se sincronizará cuando vuelva la conexión.');
      }

      reset();
      void runSync();
    } finally {
      setBusy(false);
    }
  }, [
    documento,
    puedeSalir,
    puertaTouched,
    idEntrada,
    tipoDoc,
    capturaRaw,
    metodoAut,
    online,
    ingresoClientId,
    reset,
  ]);

  const displayNombre = (() => {
    if (persona) {
      return `${persona.nombres} ${persona.apellidos}`.trim();
    }
    if (ingresoAbierto) {
      return `${ingresoAbierto.nombres} ${ingresoAbierto.apellidos}`.trim();
    }
    return '';
  })();

  const displayTipo =
    persona?.nom_tipo_persona || ingresoAbierto?.nom_tipo_persona || 'Registrado';

  const canContinueDocumento = documento.length >= MIN_DIGITS;
  const canConfirmPuerta = puertaTouched && idEntrada > 0 && !busy;
  const canGoBack = step !== 'documento' && !busy && !consultLoading;

  const puertas = useMemo(
    () => puertasParaModo(catalogos?.entradas ?? [], 'egreso'),
    [catalogos?.entradas]
  );

  return {
    step,
    documento,
    idEntrada,
    persona,
    ingresoAbierto,
    puedeSalir,
    consultLoading,
    busy,
    puertas,
    displayNombre,
    displayTipo,
    canContinueDocumento,
    canConfirmPuerta,
    appendDigit,
    deleteDigit,
    applyScan,
    continueFromDocumento,
    correct,
    goBack,
    canGoBack,
    confirmIdentity,
    selectPuerta,
    confirmRegister,
    reset,
  };
}
