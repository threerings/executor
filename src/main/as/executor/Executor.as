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

    /** Dispatched every time a submitted job completes, whether it succeeds or fails. */
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

    /** Submits all the functions through submit and returns their Futures. */
    public function submitAll (fs :Array) :Vector.<Future> {
        const result :Vector.<Future> = new Vector.<Future>(fs.length);
        for each (var f :Function in fs) result.push(submit(f));
        return result;
    }

    /**
     * Submits the given function for execution. It should take two arguments: a Function to call if
     * it succeeds, and a function to call if it fails. When called, it should execute an operation
     * asynchronously and call one of the two functions.<p>
     *
     * If the asynchronous operation returns a result, it may be passed to the success function. It
     * will then be available in the result field of the Future. If success doesn't produce a
     * result, the success function may be called with no arguments.<p>
     *
     * The failure function must be called with an argument. An error event, a stack trace, or an
     * error message are all acceptable options. When failure is called, the argument will be
     * available in the result field of the Future.
     */
    public function submit (f :Function) :Future {
        if (_shutdown) throw new Error("Submission to a shutdown executor!");
        const future :Future = new Future(onCompleted);
        _running.push(future);
        // TODO  wait to dispatch for a frame to allow listeners to be added
        f(future.onSuccess, future.onFailure);
        return future;
    }

    /** Returns true if shutdown has been called on this Executor. */
    public function get isShutdown () :Boolean { return _shutdown; }

    /**
     * Prevents additional jobs from being submitted to this Executor. After this has been called
     * terminated will be dispatched once there are no jobs running. If there are no jobs running
     * when this is called, terminated will be dispatched immediately.
     */
    public function shutdown () :void {
        const wasShutdown :Boolean = _shutdown
        _shutdown = true;
        if (!wasShutdown && _running.length == 0) terminated.dispatch(this);
    }

    protected var _shutdown :Boolean;
    protected var _running :Vector.<Future> = new Vector.<Future>();
}
}
