
import Dispatch
import os.log

/// `Timer` is a lightweight wrapper for Dispatch source timers.
public final class Timer
{
	/// Action function performed when timer is fired.
	public typealias TimerAction = (_ timer: Timer) -> Void
	
	fileprivate var timerSource: DispatchSourceTimer?
	
	fileprivate let queue: DispatchQueue
	fileprivate let action: TimerAction
	fileprivate let context: Any?
	
	fileprivate var interval: TimeInterval?

	/// The time that the timer was started.
	public fileprivate(set) var startTime: TimeInterval?

	/// The number of iterations permitted before timer is stopped.
	public fileprivate(set) var iterations: Int = 0

	/// The number of iterations for the timer.
	public fileprivate(set) var currentIteration: Int = 0
	
	/// Create a new timer to perform an action function
	/// on a dispatch queue with an optional context.
	///
	/// - Parameters:
	///   - queue: Dispatch queue to perform action function on.
	///   Defaults to global queue with default QOS priority.
	///   - context: Optional context.
	///   - action: Action function to perform.
	public init(onQueue queue: DispatchQueue = .global(), withContext context: Any? = nil, action: @escaping TimerAction)
	{
		self.queue = queue
		self.context = context
		self.action = action
	}
	
	deinit
	{
		stop()
	}
	
	/// Stop timer if it is running.
	///
	/// This function is non-destructive. A host of `Timer` can continue
	/// to access all state properties for the timer that was running.
	public func stop()
	{
		guard let timerSource else {
			return
		}
		
		timerSource.cancel()
		
		self.timerSource = nil
		
		/* Properties of timer such as start time, number of iterations, etc.
		 are not destroyed at this point because the action function might
		 be interested in this information. `stop()` is called prior to
		 performing the action function. */
	}

	/// Is timer running?
	public var active: Bool
	{
		timerSource != nil
	}

	/// Time remaining from timer start until action function will be performed.
	public var remaining: TimeInterval?
	{
		guard let interval, let startTime else {
			return nil
		}
		
		return interval - (CFAbsoluteTimeGetCurrent() - startTime)
	}

	/// Start timer.
	///
	/// By default, timers are one shot. They will wait until some point in the future,
	/// perform the action function, then stop.
	///
	/// This behavior can be changed by modifying the `iterations` argument.
	/// This argument controls the number of times the perform action will be called.
	///
	/// A value of one for this argument, which is the default, makes this a one shot timer.
	///
	/// A value greater than one and less than `Int.max` will have the timer perform the
	/// action function that number of times with an internal of `interval` between each.
	/// For example, with an `interval` of `5.0` and `iterations` of `3` the timer will
	/// work in the following fashion: wait 5 seconds, call action function, wait 5 seconds,
	/// call action function, wait 5 seconds, call action function, stop.
	///
	/// A value of `Int.max` is the equivalent of setting the number of `iterations` with
	/// no stopping point. `stop()` must be called manually to stop the timer.
	///
	/// - Parameters:
	///   - interval: How far from now in fractional seconds to perform action block.
	///   - iterations: Number of iterations to perform action function. Defaults to one.
	public func start(withInterval interval: TimeInterval, iterations: Int = 1)
	{
		precondition(interval > 0)
		precondition(iterations > 0)

		stop()
		
		timerSource = DispatchSource.makeTimerSource(queue: queue)
		
		timerSource?.setEventHandler { [weak self] in
			self?.dispatch()
		}
		
		let dispatchInterval = DispatchTimeInterval(interval)
		let intervalTime = DispatchTime.now() + dispatchInterval
		let repeatTime = (iterations > 1) ? dispatchInterval : DispatchTimeInterval.never
		
		timerSource?.schedule(deadline: intervalTime, repeating: repeatTime)
		
		self.startTime = CFAbsoluteTimeGetCurrent()
		self.interval = interval
		self.iterations = iterations
		self.currentIteration = 0
		
		timerSource?.resume()
	}
	
	fileprivate func dispatch()
	{
		currentIteration += 1
		
		if (iterations != Int.max && iterations == currentIteration) {
			stop()
		}
		
		action(self)
	}
}
