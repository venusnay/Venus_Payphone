/**
 * FiveM NUI communication utilities.
 * Handles messages from the Lua client and sends callbacks back.
 */

const isEnvBrowser = () => !(window.invokeNative);

/**
 * Sends a NUI callback to the Lua client.
 * @param {string} eventName 
 * @param {object} data 
 * @returns {Promise<any>}
 */
export async function fetchNui(eventName, data = {}) {
  if (isEnvBrowser()) {
    // In dev mode, mock responses
    console.log(`[NUI:fetchNui] ${eventName}`, data);
    return {};
  }

  const resourceName = window.GetParentResourceName
    ? window.GetParentResourceName()
    : 'payphones';

  const resp = await fetch(`https://${resourceName}/${eventName}`, {
    method: 'POST',
    headers: { 'Content-Type': 'application/json; charset=UTF-8' },
    body: JSON.stringify(data),
  });

  return resp.json();
}

/**
 * Registers a NUI message listener.
 * @param {string} action 
 * @param {function} handler 
 * @returns {function} cleanup
 */
export function onNuiMessage(action, handler) {
  const listener = (event) => {
    const { data } = event;
    if (data?.action === action) {
      handler(data);
    }
  };

  window.addEventListener('message', listener);
  return () => window.removeEventListener('message', listener);
}

/**
 * Checks if running inside FiveM NUI or a browser.
 */
export { isEnvBrowser };
