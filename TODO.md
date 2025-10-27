# TODO: Enhance Chatbot with Full App Control and Voice Assistant

## Voice Assistant Features
Alright, let's make this **brutally practical**. Here's a **complete, step-by-step TODO list** for integrating a full AI-powered voice assistant in your Park Pro app, covering **STT, TTS, wake word, command handling, and UI feedback**. I'll break it into phases so you can tackle it efficiently.

---

## **Phase 1: Dependencies & Setup**

* [x] Add `speech_to_text` for speech recognition to `pubspec.yaml`.
* [x] Add `flutter_tts` for text-to-speech to `pubspec.yaml`.
* [ ] Add `permission_handler` for microphone access (Android/iOS/windows for devlopment).
* [ ] Ensure proper Android/iOS configuration for background listening permissions.

---

## **Phase 2: Wake Word Detection**

* [x] Decide wake word: `"hey park-pro"` (good start).
* [x] Implement basic continuous listening with `speech_to_text` (for testing).
* [ ] Optionally, integrate **Porcupine** or **Snowboy** for robust offline wake word detection.
* [x] Add **UI indicator**: a small mic icon that lights up when wake word is detected.

---

## **Phase 3: Voice Listening & Timeout**

* [x] Activate **voice listening** once wake word detected.
* [x] Set **timeout**: 10 seconds (or customizable) if no speech detected.
* [x] Allow **manual cancel/stop** button.
* [x] Display **listening animation** (pulsating mic or waveform).

---

## **Phase 4: Speech-to-Text (STT)**

* [x] Convert captured voice to text using `speech_to_text`.
* [ ] Handle errors (e.g., "No speech detected", "Try again").
* [x] Send the recognized text to your **AI command parser**.

---

## **Phase 5: AI Command Processing**

* [x] Create a **command parser** for parking app actions:

  * Check available slots
  * Book a slot
  * Cancel booking
  * Show booking history
* [x] Map recognized text to **predefined app functions**.
* [x] If unrecognized, fallback to **AI response** (OpenAI, GPT API, or local model).

---

## **Phase 6: Text-to-Speech (TTS)**

* [x] Convert AI or system responses to speech using `flutter_tts`.
* [ ] Ensure smooth playback, even during animations.
* [x] Pause listening while speaking (avoid self-listening loop).

---

## **Phase 7: UI Feedback & Experience**

* [x] Visual mic icon for listening state (active/inactive).
* [x] Display recognized text on screen while speaking.
* [x] Show system/AI response in chat bubbles **and** TTS simultaneously.
* [ ] Add error feedback if speech or command fails.

---

## **Phase 8: Offline & Performance Optimizations**

* [ ] Consider **offline STT fallback** for areas with poor internet.
* [ ] Optimize continuous listening for **battery efficiency**.
* [ ] Avoid running heavy AI inference on device (use API if needed).

---

## **Phase 9: Testing**

* [x] Test in **quiet and noisy environments**.
* [x] Test **wake word detection accuracy**.
* [x] Test **all commands** with different phrasings.
* [x] Ensure **TTS clarity** and **proper audio focus**.

---

💡 **Pro tip:** add small with **push-to-talk** (button) mode, get the commands working perfectly with **wake-word detection**.




## Full App Control via Chat/Voice
- [x] Add new intents in intents.py: cancel_booking, edit_profile, view_payment_history, logout, settings, feedback, emergency
- [x] Enhance entity extraction in ai_model.py for dates, times, durations
- [x] Add proxy methods in ai_model.py for new intents (e.g., cancel booking via backend)
- [x] Implement automatic page switching and booking actions in chatbot_page.dart
- [x] Exclude payment actions from automatic processes (require user confirmation)
- [x] Add confirmation dialogs in chat for critical actions
- [x] Improve error handling and contextual responses

## Testing and Followup
- [x] Test voice activation and input on device/emulator
- [x] Test full app control scenarios (navigation, booking, etc.)
- [x] Update backend if new APIs needed
- [x] User testing for usability
