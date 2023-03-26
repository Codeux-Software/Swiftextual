/* *********************************************************************
 *
 *         Copyright (c) 2015 - 2020 Codeux Software, LLC
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

#import <objc/message.h>

NS_ASSUME_NONNULL_BEGIN

#pragma mark -
#pragma mark Swizzling

/* Swizzle functions take strings to make it difficult for Apple to find private APIs */
void XRExchangeInstanceMethod(NSString *className, NSString *originalMethod, NSString *replacementMethod)
{
	NSCParameterAssert(className != nil);
	NSCParameterAssert(originalMethod != nil);
	NSCParameterAssert(replacementMethod != nil);

	Class class = NSClassFromString(className);

	SEL originalSelector = NSSelectorFromString(originalMethod);
	SEL swizzledSelector = NSSelectorFromString(replacementMethod);

	Method originalMethodDcl = class_getInstanceMethod(class, originalSelector);
	Method swizzledMethodDcl = class_getInstanceMethod(class, swizzledSelector);

	BOOL methodAdded =
	class_addMethod(class,
					originalSelector,
					method_getImplementation(swizzledMethodDcl),
					method_getTypeEncoding(swizzledMethodDcl));

	if (methodAdded) {
		class_replaceMethod(class,
							swizzledSelector,
							method_getImplementation(originalMethodDcl),
							method_getTypeEncoding(originalMethodDcl));
	} else {
		method_exchangeImplementations(originalMethodDcl, swizzledMethodDcl);
	}
}

void XRExchangeClassMethod(NSString *className, NSString *originalMethod, NSString *replacementMethod)
{
	NSCParameterAssert(className != nil);
	NSCParameterAssert(originalMethod != nil);
	NSCParameterAssert(replacementMethod != nil);

	Class classClass = NSClassFromString(className);

	Class class = object_getClass(classClass);

	SEL originalSelector = NSSelectorFromString(originalMethod);
	SEL swizzledSelector = NSSelectorFromString(replacementMethod);

	Method originalMethodDcl = class_getClassMethod(class, originalSelector);
	Method swizzledMethodDcl = class_getClassMethod(class, swizzledSelector);

	BOOL methodAdded =
	class_addMethod(class,
					originalSelector,
					method_getImplementation(swizzledMethodDcl),
					method_getTypeEncoding(swizzledMethodDcl));

	if (methodAdded) {
		class_replaceMethod(class,
							swizzledSelector,
							method_getImplementation(originalMethodDcl),
							method_getTypeEncoding(originalMethodDcl));
	} else {
		method_exchangeImplementations(originalMethodDcl, swizzledMethodDcl);
	}
}

NS_ASSUME_NONNULL_END
