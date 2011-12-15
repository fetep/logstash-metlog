package com.mozilla.services;

import com.sun.jna.Library;
import com.sun.jna.Callback;

/*
 * This interface exposes the signal mechanisms for UNIX
 *
 */

public interface ISignalHandler extends Library {
    ISignalFunction signal(int signal, ISignalFunction func);
}
