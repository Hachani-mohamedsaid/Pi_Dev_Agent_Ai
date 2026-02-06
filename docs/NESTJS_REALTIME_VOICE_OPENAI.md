# Voix ChatGPT originale – OpenAI Realtime Voice API (NestJS)

Proxy WebSocket NestJS vers l’API OpenAI Realtime pour exposer la **voix ChatGPT originale** à l’app Flutter.

---

## 1. Prérequis

- Node.js 18+
- NestJS
- Clé API OpenAI (accès Realtime)
- `npm i ws @nestjs/websockets @nestjs/platform-ws dotenv`

---

## 2. Variables d'environnement

```env
OPENAI_API_KEY=sk-xxxxxxxx
```

---

## 3. Service Realtime (proxy vers OpenAI)

**Fichier : `src/realtime/realtime-voice.service.ts`**

```typescript
import WebSocket from 'ws';

const OPENAI_REALTIME_URL = 'wss://api.openai.com/v1/realtime?model=gpt-4o-realtime-preview';

export class RealtimeVoiceService {
  private openaiWs: WebSocket | null = null;

  connectToOpenAI(
    onAudioDelta: (base64: string) => void,
    onTextDelta?: (text: string) => void,
  ): Promise<void> {
    return new Promise((resolve, reject) => {
      const apiKey = process.env.OPENAI_API_KEY;
      if (!apiKey) {
        reject(new Error('OPENAI_API_KEY is not set'));
        return;
      }

      this.openaiWs = new WebSocket(OPENAI_REALTIME_URL, {
        headers: {
          Authorization: `Bearer ${apiKey}`,
          'OpenAI-Beta': 'realtime=v1',
        },
      });

      this.openaiWs.on('open', () => {
        this.openaiWs!.send(JSON.stringify({
          type: 'session.update',
          session: {
            voice: 'alloy',
            instructions:
              'Understand any spoken language and respond naturally in the same language. Réponds en français si on te parle en français.',
          },
        }));
        resolve();
      });

      this.openaiWs.on('message', (data: Buffer) => {
        try {
          const msg = JSON.parse(data.toString());
          if (msg.type === 'response.audio.delta' && msg.delta) onAudioDelta(msg.delta);
          if (msg.type === 'response.output_text.delta' && onTextDelta && msg.delta) onTextDelta(msg.delta);
        } catch (_) {}
      });

      this.openaiWs.on('error', reject);
      this.openaiWs.on('close', () => { this.openaiWs = null; });
    });
  }

  sendAudioChunk(base64Audio: string): void {
    if (this.openaiWs?.readyState === WebSocket.OPEN) {
      this.openaiWs.send(JSON.stringify({ type: 'input_audio_buffer.append', audio: base64Audio }));
    }
  }

  commitAndCreateResponse(): void {
    if (this.openaiWs?.readyState === WebSocket.OPEN) {
      this.openaiWs.send(JSON.stringify({ type: 'input_audio_buffer.commit' }));
      this.openaiWs.send(JSON.stringify({ type: 'response.create' }));
    }
  }

  close(): void {
    if (this.openaiWs) {
      this.openaiWs.close();
      this.openaiWs = null;
    }
  }
}
```

---

## 4. WebSocket Gateway

**Fichier : `src/realtime/realtime.gateway.ts`**

À adapter selon ton setup NestJS (utilisation de `@WebSocketGateway`, gestion des clients avec le package `ws`). Idée : à chaque connexion client Flutter, créer une instance de `RealtimeVoiceService`, connecter à OpenAI, et faire le pont :

- **Client → NestJS** : messages `input_audio_buffer.append` (base64) et `input_audio_buffer.commit`.
- **NestJS → Client** : envoyer les événements `response.audio.delta` (base64) et optionnellement `response.output_text.delta`.

Chemin conseillé pour Flutter : `ws://host/realtime-voice` ou `wss://host/realtime-voice`.

---

## 5. Flutter

Dans `lib/core/config/api_config.dart`, définir **realtimeVoiceWsUrl** (ex. `wss://ton-backend.up.railway.app/realtime-voice`). L’app se connecte en WebSocket, envoie l’audio micro en base64 (PCM 24 kHz mono), reçoit les deltas audio et les joue (voir client Realtime dans le projet Flutter).
