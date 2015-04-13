SayKit
====

Voice composition interface for OS X.

See `man say` for the basis.

Example
----

```
import SayKit

SKSay(text: "Hello, World!").play()  // play
SKSay(text: "Hello, World!").writeToURL(NSURL(string: "/tmp/test.aiff")) // save to file

voices = SKVoice.voices.filter({ $0.locale == 'en_US' }) // filter en_US voices
SKSay(text: "Specific voice", voice: voices[0]).play() // play with specific voice
```