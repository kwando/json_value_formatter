import { Ok, Error } from "./gleam.mjs";

export function formatJson(input) {
  try {
    const parsed = JSON.parse(input);
    return new Ok(JSON.stringify(parsed, null, 2));
  } catch (e) {
    return new Error(undefined);
  }
}

export function getSessionStorage(key) {
  const item = window.sessionStorage.getItem(key);

  if (item === null) {
    return new Error(undefined);
  } else {
    return new Ok(item);
  }
}

export function setSessionStorage(key, value) {
  window.sessionStorage.setItem(key, value);
  return;
}

export function copyTextToClipboard(text) {
  navigator.clipboard.writeText(text);
}
