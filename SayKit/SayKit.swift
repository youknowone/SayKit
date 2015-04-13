//
//  Say.swift
//  VoiceForYou
//
//  Created by Jeong YunWon on 2015. 4. 10..
//  Copyright (c) 2015년 youknowone.org. All rights reserved.
//

import Cocoa

/**
    Voice
*/
public class SKVoice: NSObject {
    public let name: String
    public let locale: String
    public let comment: String

    public override var description: String {
        get {
            return "<SKVoice: '\(self.name)'(\(self.locale)), '\(self.comment)'>"
        }
    }

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
    public static let voices: [SKVoice] = {
        let output = NSPipe()
        let task = NSTask()
        task.launchPath = SKSay.LAUNCH_PATH
        task.arguments = ["--voice=?"]
        task.standardOutput = output
        task.launch()
        task.waitUntilExit()

        var error: NSError? = nil
        let regex = NSRegularExpression(pattern: "(.*?) {4,}([a-z]{2,3}_[A-Z]{2,}) +# (.*)", options: NSRegularExpressionOptions.UseUnicodeWordBoundaries, error: &error)!
        assert(error == nil)
        let data = output.fileHandleForReading.readDataToEndOfFile()
        let string = NSString(data: data, encoding: NSUTF8StringEncoding)!

        var voices: [SKVoice] = []
        for match in regex.matchesInString(string as String, options: NSMatchingOptions.allZeros, range: NSMakeRange(0, string.length)) {
            let name = string.substringWithRange(match.rangeAtIndex(1))
            let locale = string.substringWithRange(match.rangeAtIndex(2))
            let comment = string.substringWithRange(match.rangeAtIndex(3))
            voices.append(SKVoice(name: name, locale: locale, comment: comment))
        }
        return voices
    }()
}

/**
    Easy-to-use interface for `say` command in OS X.
*/
public class SKSay: NSObject {
    public static let LAUNCH_PATH = "/usr/bin/say"

    public let task = NSTask()

    public var text: String
    public var voice: SKVoice?
    public var outputFile: String? = nil

    public override var description: String {
        get {
            return "<SKSay: '\(self.text)'>"
        }
    }

    /** Initialize a say interface with given text and voice.

        @param text A text string to composite speech.
        @param voice A voice to composite speech. If given voice is nil, default voice is used.
    */
    public init(text: String, voice: SKVoice?) {
        self.text = text
        self.voice = voice
        super.init()
        self.task.launchPath = SKSay.LAUNCH_PATH
    }

    /** Initialize a say interface with given text and default voice.

        @param text A text string to composite speech.
    */
    public convenience init(text: String) {
        self.init(text: text, voice: nil)
    }

    /** Initialize a say interface with given text and voice with given voice name.

        @param text A text string to composite speech.
        @param voice A voice name to composite speech. If given voice name is invalid, nil is returned.
    */
    public convenience init?(text: String, voiceName: String) {
        let voices = SKVoice.voices.filter({ $0.name == voiceName })
        if voices.count == 0 {
            self.init(text: text, voice: nil)
            return nil
        } else {
            self.init(text: text, voice: voices[0])
        }
    }

    func composeArguments() {
        var arguments: [AnyObject] = []
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

    /** Composite and play speech.

        @param waitUntilDone Wait until done and return if true; otherwise not.
    */
    public func play(waitUntilDone: Bool) {
        self.outputFile = nil
        self.composeArguments()
        self.task.launch()
        if waitUntilDone {
            self.task.waitUntilExit()
        }
    }

    /** Composite and write speech to URL.

        File format is .aiff.

        @param URL File URL to write speech.
    */
    public func writeToURL(URL: NSURL, atomically: Bool) {
        self.outputFile = URL.path!
        self.composeArguments()
        self.task.launch()
    }
}
