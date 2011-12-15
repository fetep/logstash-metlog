package com.mozilla.services;

import com.sun.jna.Callback;

public interface ISignalFunction extends Callback {
    void invoke(int signal);
}
