//
//  SayKit.swift
//  SayKit
//
//  Created by Jeong YunWon on 2015. 4. 10..
//  Copyright (c) 2015 youknowone.org. All rights reserved.
//

import Cocoa

/**
    Easy-to-use interface for `say` command in OS X.
*/
open class Say: NSObject {
    open static let LAUNCH_PATH = "/usr/bin/say"

    open let task = Process()

    open var text: String
    open var voice: Voice?
    open var outputFile: String? = nil

    open override var description: String {
        get {
            return "<Say: '\(self.text)'>"
        }
    }

    /**
        Construct a say interface with given text and voice.

        - Parameters:
            - text: A text string to composite speech.
            - voice: A voice to composite speech. If given voice is nil, default voice is used.
    */
    public init(text: String, voice: Voice?) {
        self.text = text
        self.voice = voice
        super.init()
        self.task.launchPath = Say.LAUNCH_PATH
    }

    /**
        Construct a say interface with given text and default voice.

        - Parameter text: A text string to composite speech.
    */
    public convenience init(text: String) {
        self.init(text: text, voice: nil)
    }

    /**
        Construct a say interface with given text and voice with given voice name.

        - Parameter text: A text string to composite speech.
        - Parameter voice: A voice name to composite speech. If given voice name is invalid, nil is returned.
    */
    public convenience init?(text: String, voiceName: String) {
        let voices = Voice.voices.filter({ $0.name == voiceName })
        if voices.count == 0 {
            self.init(text: text, voice: nil)
            return nil
        } else {
            self.init(text: text, voice: voices[0])
        }
    }

    func composeArguments() {
        var arguments: [String] = []
        if let voice = self.voice {
            arguments.append("-v")
            arguments.append(voice.name)
        }
        if let output = self.outputFile {
            arguments.append("-o")
            arguments.append(output)
        }
        arguments.append(self.text)
        self.task.arguments = arguments
    }

    /** 
        Composite and play speech.

        - Parameter waitUntilDone: Wait until done and return if true; otherwise not.
    */
    open func play(_ waitUntilDone: Bool) {
        self.outputFile = nil
        self.composeArguments()
        self.task.launch()
        if waitUntilDone {
            self.task.waitUntilExit()
        }
    }

    /** 
        Composite and write speech to URL.

        File format is .aiff.

        - Parameters:
            - URL: File URL to write speech.
            - atomically: Currently ignored.
    */
    open func writeToURL(_ URL: Foundation.URL, atomically: Bool) {
        self.outputFile = URL.path
        self.composeArguments()
        self.task.launch()
    }
}

/**
    Voice object for Say.
 
    Voice objects will be automatically generated by `Voice.voices()`.
    Do not create one yourself.
 */
open class Voice: NSObject {
    open let name: String
    open let locale: String
    open let comment: String

    open override var description: String {
        get {
            return "<Voice: '\(self.name)'(\(self.locale)), '\(self.comment)'>"
        }
    }

    /**
        Construct a voice object for Say.
     
        Voice objects will be automatically generated by `Voice.voices()`.
        Do not create one yourself.
     
        - Parameters:
            - name: Name of the voice.
            - locale: Locale of the voice.
            - comment: Comment of the voice.
     */
    public init(name: String, locale: String, comment: String) {
        self.name = name
        self.locale = locale
        self.comment = comment
        super.init()
    }

    /**
        List of voices of current system.

        The list is equivelent to `say --voice=?` for the system.
     */
    open static let voices: [Voice] = {
        let output = Pipe()
        let task = Process()
        task.launchPath = Say.LAUNCH_PATH
        task.arguments = ["--voice=?"]
        task.standardOutput = output
        task.launch()
        task.waitUntilExit()

        var error: NSError? = nil
        let regex = try! NSRegularExpression(pattern: "(.*?) {4,}([a-z]{2,3}_[A-Z]{2,}) +# (.*)", options: NSRegularExpression.Options.useUnicodeWordBoundaries)
        assert(error == nil)
        let data = output.fileHandleForReading.readDataToEndOfFile()
        let string = NSString(data: data, encoding: String.Encoding.utf8.rawValue)!

        var voices: [Voice] = []
        for match in regex.matches(in: string as String, options: NSRegularExpression.MatchingOptions(), range: NSMakeRange(0, string.length)) {
            let name = string.substring(with: match.rangeAt(1))
            let locale = string.substring(with: match.rangeAt(2))
            let comment = string.substring(with: match.rangeAt(3))
            voices.append(Voice(name: name, locale: locale, comment: comment))
        }
        return voices
    }()
}
