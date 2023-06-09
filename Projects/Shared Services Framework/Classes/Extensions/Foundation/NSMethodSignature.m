/* *********************************************************************
 *
 *         Copyright (c) 2016 - 2018 Codeux Software, LLC
 *     Please see ACKNOWLEDGEMENT for additional information.
 *
 * Redistribution and use in source and binary forms, with or without
 * modification, are permitted provided that the following conditions
 * are met:
 *
 *  * Redistributions of source code must retain the above copyright
 *    notice, this list of conditions and the following disclaimer.
 *  * Redistributions in binary form must reproduce the above copyright
 *    notice, this list of conditions and the following disclaimer in the
 *    documentation and/or other materials provided with the distribution.
 *  * Neither the name of "Codeux Software, LLC", nor the names of its
 *    contributors may be used to endorse or promote products derived
 *    from this software without specific prior written permission.
 *
 * THIS SOFTWARE IS PROVIDED BY THE AUTHOR AND CONTRIBUTORS ``AS IS'' AND
 * ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
 * IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE
 * ARE DISCLAIMED. IN NO EVENT SHALL THE AUTHOR OR CONTRIBUTORS BE LIABLE
 * FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL
 * DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS
 * OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION)
 * HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT
 * LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY
 * OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF
 * SUCH DAMAGE.
 *
 *********************************************************************** */

#import "OSLog.h"

NS_ASSUME_NONNULL_BEGIN

@implementation NSMethodSignature (CSMethodSignatureHelper)

- (BOOL)validateMethodIsValidSenderDestination
{
	if (strcmp(self.methodReturnType, @encode(void)) != 0) {
		os_log_error(XRLogging.frameworkLog,
					 "Method '%@' should not return a value.",
					 self.description);

		return NO;
	} else if (self.numberOfArguments != 3) {
		os_log_error(XRLogging.frameworkLog,
					 "Method '%@' should take only one argument.",
					 self.description);

		return NO;
	}

	const char *argumentType = [self getArgumentTypeAtIndex:2];

	if (strcmp(argumentType, @encode(id)) != 0) {
		os_log_error(XRLogging.frameworkLog,
					 "First argument of '%@' should be an object.",
					 self.description);

		return NO;
	}

	return YES;
}

@end

NS_ASSUME_NONNULL_END
