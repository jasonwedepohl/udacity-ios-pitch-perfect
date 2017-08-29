# Pitch Perfect

Pitch Perfect is an app for iOS, and one of the projects composing Udacity's iOS nanodegree. Though all students implement the same app, we are encouraged to think of ways to make our apps stand out.

The core requirements for this app:
- There are two screens, one for recording and one for playback.
- The user may record audio on the first screen, then hit Stop to segue to the second screen.
- The second screen allows playback with six possible modifiers: tempo decrease, tempo increase, pitch decrease, pitch increase, echo, and reverb. 
- The app layout should be responsive to orientation changes as well as iPhone/iPad display sizes.

This version of the app fulfils those requirements and adds some features:
- Speech is recognised and transcribed using the same technology that powers Siri (this is done while the user is recording speech on the first screen, but the transcribed text is shown on the second screen as well).
- The user may pause and resume while recording on the first screen.
- The user may pause and resume while playing back audio on the second screen.

Notes:
- The app asks for the user's permission to use the microphone and to perform speech recognition. The latter is necessary since audio is sent to Apple's servers for recognition.
- Speech transcription happens when the user hits Record. Since the audio must be sent to Apple's servers, there will be a short delay between the user saying something and their transcribed speech appearing on screen. This delay will be better or worse depending on the user's internet connection.


