//
// Executor - Copyright 2012 Three Rings Design

package executor {

import org.osflash.signals.Signal;

public class Future
{
    public function Future (f :Function, onCompleted :Function) {
        // TODO  wait to dispatch for a frame to allow listeners to be added
        _onCompleted = onCompleted;
        f(onSuccess, onFailure);
    }

    public function get succeeded () :Signal {
        return _onSuccess || (_onSuccess = new Signal(Object));
    }

    public function get failed () :Signal {
        return _onFailure || (_onFailure = new Signal(Object));
    }

    public function get completed () :Signal {
        return _onCompletion || (_onCompletion = new Signal(Future));
    }

    protected function onSuccess (...result) :void {
        if (result.length > 0) {
            _result = result[0];
        }
        _succeeded = true;
        if (_onSuccess) _onSuccess.dispatch(_result);
        if (_onCompletion) _onCompletion.dispatch(this);
        _onCompleted(this);
        _onCompleted = null;// Allow Executor to be GC'd if the Future is hanging around
    }

    public function onFailure (error :Object) :void {
        _result = error;
        _failed = true;
        if (_onFailure) _onFailure.dispatch(error);
        if (_onCompletion) _onCompletion.dispatch(this);
        _onCompleted(this);
        _onCompleted = null;// Allow Executor to be GC'd if the Future is hanging around
    }

    public function get isSuccessful () :Boolean { return _succeeded; }
    public function get isFailure  ():Boolean { return _failed; }
    public function get isComplete  ():Boolean { return _failed || _succeeded; }

    public function get result () :* { return _result; }

    protected var _failed :Boolean
    protected var _succeeded :Boolean;
    protected var _result :Object = undefined;

    // All Future signals are created lazily
    protected var _onSuccess :Signal;
    protected var _onFailure :Signal;
    protected var _onCompletion :Signal;
    protected var _onCompleted :Function;
}
}
