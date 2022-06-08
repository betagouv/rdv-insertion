const camelToSnakeCase = (string) =>
  string.replace(/[A-Z]/g, (letter) => `_${letter.toLowerCase()}`);

export default camelToSnakeCase;
