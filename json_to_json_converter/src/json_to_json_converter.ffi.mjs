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

export function enableTab(id) {
  var el = document.getElementById(id);
  el.onkeydown = function (e) {
    if (e.keyCode === 9) {
      // tab was pressed

      // get caret position/selection
      var val = this.value,
        start = this.selectionStart,
        end = this.selectionEnd;

      // set textarea value to: text before caret + tab + text after caret
      this.value = val.substring(0, start) + "\t" + val.substring(end);

      // put caret at right position again
      this.selectionStart = this.selectionEnd = start + 1;

      // prevent the focus lose
      return false;
    }
  };
}
