//
// Executor - Copyright 2012 Three Rings Design

package executor {

import org.osflash.signals.Signal;

public class Executor
{
    /** Dispatched when the all jobs have been completed in a shutdown executor. */
    public const terminated :Signal = new Signal(Executor);

    /** Dispatched every time a submitted job succeeds. */
    public const succeeded :Signal = new Signal(Future);

    /** Dispatched every time a submitted job fails. */
    public const failed :Signal = new Signal(Future);

    /** Dispatched every time a submitted job completes, whether it succeeds or failes. */
    public const completed :Signal = new Signal(Future);

    /**
     * Called by Future directly when it's done. It uses this instead of dispatching the completed
     * signal as that allows the completed signal to completely dispatch before Executor checks for
     * termination and possibly dispatches that.
     */
    protected function onCompleted (f :Future) :void {
        if (f.succeeded) succeeded.dispatch(f)
        else failed.dispatch(f)

        var removed :Boolean = false;
        for (var ii :int = 0; ii < _running.length && !removed; ii++) {
            if (_running[ii] == f) {
                _running.splice(ii--, 1);
                removed = true;
            }
        }
        if (!removed) throw new Error("Unknown future completed? " + f);
        completed.dispatch(f);

        if (_running.length == 0 && _shutdown) terminated.dispatch(this);
    }

    public function submitAll (fs :Array) :Vector.<Future> {
        const result :Vector.<Future> = new Vector.<Future>(fs.length);
        for each (var f :Function in fs) result.push(submit(f));
        return result;
    }

    public function submit (f :Function) :Future {
        if (_shutdown) throw new Error("Submission to a shutdown executor!");
        _running.push(new Future(f, onCompleted));
        return _running[_running.length - 1];
    }

    public function get isShutdown () :Boolean { return _shutdown; }

    public function shutdown () :void {
        _shutdown = true;
        if (_running.length == 0) terminated.dispatch(this);
    }

    protected var _shutdown :Boolean;
    protected var _running :Vector.<Future> = new Vector.<Future>();
}
}
