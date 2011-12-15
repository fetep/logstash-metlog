package com.mozilla.services;

import com.sun.jna.Native;
/*
 * Just a sipmle proxy class  so that you can just instantiate this
 * one class and do all your signal callback hooks through this class
 * without having to interact with low level JNA stuff.
 *
 */
public class Signal {

    ISignalHandler _handler;

    private static Signal _instance;

    private Signal() {
        _handler = (ISignalHandler) Native.loadLibrary("c", ISignalHandler.class);
    }

    /*
     * The signal mechanism must be a singleton or else we will load
     * the C library multiple times.
     */
    public static synchronized Signal getInstance()
    {
        if (Signal._instance == null) {
            Signal._instance = new Signal();
        }
        return Signal._instance;
    }

    public void register_callback(int signal, ISignalFunction cb)
    {
        _handler.signal(signal, cb);
    }

}
