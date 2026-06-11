export type PuertaItem = { id: number; nombre: string };

/** Devuelve las puertas tal cual vienen del catálogo/BD (sin renombrar). */
export function puertasParaModo(
  entradas: PuertaItem[],
  _mode: 'ingreso' | 'egreso'
): PuertaItem[] {
  return entradas;
}
