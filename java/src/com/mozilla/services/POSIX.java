package com.mozilla.services;

import com.sun.jna.Native;
import com.sun.jna.Platform;
import com.sun.jna.Callback;
 
/*
 *
 * This code can be used to trap signals without having to deal with
 * the private sun.misc.* APIs which are not actually supported
 * anyway.
 *
 * You'll need JNA 3.4 and  the platform JAR for JNA to build this
 *
 * Compile this with: 
 *   javac -cp jna-3.4.0.jar:jna-platform-3.4.0.jar  POSIX.java
 *
 * Run this with :
 *   java -cp jna-3.4.0.jar:jna-platform-3.4.0.jar  POSIX.java
 *
 * When executing, don't forget the -Xrs flag as Java normally catches
 * some signals to just shutdown the VM.
 *
 */
public class POSIX implements ISignalFunction {

    public void invoke(int signal) {
        System.out.println("signal :" + signal);
    }

    public void do_stuff()
    {
        Signal registry = Signal.getInstance();
        registry.register_callback(1, this);

        while (true)
        {
            System.out.println("waiting on stuff to happen...");
            try {
                Thread.sleep(1000);
            } catch (InterruptedException e) {
                break;
            }

        }
    }

    public static void main(String[] args)  {
        POSIX p = new POSIX();
        p.do_stuff();

    }
}
