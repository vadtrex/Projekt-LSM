/**
 * opfs_helper.js
 *
 * Implementacja window.flutterGemmaOPFS wymagana przez flutter_gemma (>=0.11).
 * Umożliwia przechowywanie i strumieniowanie dużych modeli (>2 GB) w przeglądarce
 * przez Origin Private File System (OPFS).
 *
 * Wymagania przeglądarki: Chrome 86+, Edge 86+, Safari 15.2+
 * Firefox: OPFS nie jest obsługiwane.
 */

(function () {
  'use strict';

  const OPFS_DIR = 'flutter_gemma_models';

  /** Pobiera katalog roboczy OPFS (tworzy jeśli nie istnieje). */
  async function getOpfsDir() {
    const root = await navigator.storage.getDirectory();
    return await root.getDirectoryHandle(OPFS_DIR, { create: true });
  }

  const flutterGemmaOPFS = {
    /**
     * Sprawdza czy model jest zapisany w OPFS.
     * @param {string} filename
     * @returns {Promise<boolean>}
     */
    async isModelCached(filename) {
      try {
        const dir = await getOpfsDir();
        await dir.getFileHandle(filename);
        return true;
      } catch {
        return false;
      }
    },

    /**
     * Zwraca rozmiar pliku w OPFS lub null jeśli nie istnieje.
     * @param {string} filename
     * @returns {Promise<number|null>}
     */
    async getCachedModelSize(filename) {
      try {
        const dir = await getOpfsDir();
        const handle = await dir.getFileHandle(filename);
        const file = await handle.getFile();
        return file.size;
      } catch {
        return null;
      }
    },

    /**
     * Pobiera model z sieci i zapisuje w OPFS z raportowaniem postępu.
     * @param {string} url
     * @param {string} filename
     * @param {string|null} authToken
     * @param {function(number):void} onProgress — 0..100
     * @param {AbortSignal|null} abortSignal
     * @returns {Promise<boolean>}
     */
    async downloadToOPFS(url, filename, authToken, onProgress, abortSignal) {
      const headers = {};
      if (authToken) {
        headers['Authorization'] = `Bearer ${authToken}`;
      }

      const response = await fetch(url, {
        headers,
        signal: abortSignal ?? undefined,
      });

      if (!response.ok) {
        throw new Error(`Download failed: ${response.status} ${response.statusText}`);
      }

      const contentLength = parseInt(response.headers.get('Content-Length') || '0', 10);
      const reader = response.body.getReader();

      const dir = await getOpfsDir();
      const fileHandle = await dir.getFileHandle(filename, { create: true });
      const writable = await fileHandle.createWritable();

      let received = 0;

      try {
        while (true) {
          const { done, value } = await reader.read();
          if (done) break;

          await writable.write(value);
          received += value.length;

          if (contentLength > 0 && onProgress) {
            const progress = Math.round((received / contentLength) * 100);
            onProgress(progress);
          }
        }

        await writable.close();
        if (onProgress) onProgress(100);
        return true;
      } catch (e) {
        await writable.abort();
        // Usuń niekompletny plik przy błędzie
        try { await dir.removeEntry(filename); } catch {}
        throw e;
      }
    },

    /**
     * Zwraca ReadableStreamDefaultReader dla streamingu modelu do MediaPipe.
     * @param {string} filename
     * @returns {Promise<ReadableStreamDefaultReader>}
     */
    async getStreamReader(filename) {
      const dir = await getOpfsDir();
      const fileHandle = await dir.getFileHandle(filename);
      const file = await fileHandle.getFile();
      return file.stream().getReader();
    },

    /**
     * Usuwa model z OPFS.
     * @param {string} filename
     * @returns {Promise<void>}
     */
    async deleteModel(filename) {
      try {
        const dir = await getOpfsDir();
        await dir.removeEntry(filename);
      } catch {
        // Ignoruj błąd jeśli plik nie istnieje
      }
    },

    /**
     * Zwraca statystyki przechowywania (użycie i limit).
     * @returns {Promise<{usage: number, quota: number}>}
     */
    async getStorageStats() {
      if (navigator.storage && navigator.storage.estimate) {
        const estimate = await navigator.storage.estimate();
        return { usage: estimate.usage || 0, quota: estimate.quota || 0 };
      }
      return { usage: 0, quota: 0 };
    },

    /**
     * Usuwa wszystkie pliki z OPFS (tylko do testów/dev).
     * @returns {Promise<number>} Liczba usuniętych plików
     */
    async clearAll() {
      const dir = await getOpfsDir();
      let count = 0;
      for await (const [name] of dir.entries()) {
        await dir.removeEntry(name);
        count++;
      }
      return count;
    },
  };

  window.flutterGemmaOPFS = flutterGemmaOPFS;
  console.log('[opfs_helper] flutterGemmaOPFS zainicjalizowany.');
})();
