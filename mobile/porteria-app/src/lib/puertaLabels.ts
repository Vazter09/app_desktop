/** Misma puerta física; en egreso mostramos etiqueta de salida. */
export function puertaNombreEgreso(nombre: string): string {
  if (!nombre.trim()) return 'Salida';
  return nombre.replace(/\bentrada(s)?\b/gi, (_, plural: string | undefined) =>
    plural ? 'Salidas' : 'Salida'
  );
}

export type PuertaItem = { id: number; nombre: string };

export function puertasParaModo(
  entradas: PuertaItem[],
  mode: 'ingreso' | 'egreso'
): PuertaItem[] {
  if (mode === 'ingreso') return entradas;
  return entradas.map((e) => ({ id: e.id, nombre: puertaNombreEgreso(e.nombre) }));
}
