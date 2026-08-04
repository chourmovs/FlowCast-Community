export function withBase(path = ''): string {
  const base = import.meta.env.BASE_URL.replace(/\/+$/, '');
  const cleanPath = path.replace(/^\/+/, '');

  if (!cleanPath) {
    return `${base}/`;
  }

  return `${base}/${cleanPath}`;
}
