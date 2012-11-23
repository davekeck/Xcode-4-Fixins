#import <Foundation/Foundation.h>

#define XCFixinPreflight()                         \
    if (!XCFixinShouldLoad())                      \
        return;                                    \
                                                   \
    static NSUInteger loadAttempt = 0;             \
    loadAttempt++;                                 \
    NSLog(@"%@ initialization attempt %ju/%ju...", \
		  NSStringFromClass([self class]),         \
		  (uintmax_t)loadAttempt,                  \
		  (uintmax_t)XCFixinMaxLoadAttempts);

#define XCFixinPostflight()                                                                                 \
    NSLog(@"%@ initialization successful!", NSStringFromClass([self class]));                               \
    return;                                                                                                 \
    failed:                                                                                                 \
    {                                                                                                       \
        NSLog(@"%@ initialization failed.", NSStringFromClass([self class]));                               \
                                                                                                            \
        if (loadAttempt < XCFixinMaxLoadAttempts)                                                           \
        {                                                                                                   \
            dispatch_after(dispatch_time(DISPATCH_TIME_NOW, 1.0 * NSEC_PER_SEC), dispatch_get_main_queue(), \
                ^(void)                                                                                     \
                {                                                                                           \
                    [self pluginDidLoad: plugin];                                                           \
                });                                                                                         \
        }                                                                                                   \
                                                                                                            \
        else NSLog(@"%@ failing permanently. :(", NSStringFromClass([self class]));                         \
    }

#define XCFixinAssertMessageFormat @"Assertion failed (file: %s, function: %s, line: %u): %s\n"
#define XCFixinNoOp (void)0

#define XCFixinAssertOrPerform(condition, action)                                                      \
({                                                                                                     \
    bool __evaluated_condition = false;                                                                \
                                                                                                       \
    __evaluated_condition = (condition);                                                               \
                                                                                                       \
    if (!__evaluated_condition)                                                                        \
    {                                                                                                  \
        NSLog(XCFixinAssertMessageFormat, __FILE__, __PRETTY_FUNCTION__, __LINE__, (#condition));      \
        action;                                                                                        \
    }                                                                                                  \
})

#define XCFixinAssertOrRaise(condition) XCFixinAssertOrPerform((condition), [NSException raise: NSGenericException format: @"An XCFixin exception occurred"])

#define XCFixinConfirmOrPerform(condition, action)      \
({                                                      \
    if (!(condition))                                   \
    {                                                   \
        action;                                         \
    }                                                   \
})

BOOL XCFixinShouldLoad(void);
extern const NSUInteger XCFixinMaxLoadAttempts;

/* This function overrides a method at the given class level, and returns the old implementation. If no method existed at
   the given class' level, a new method is created at that level, and the superclass' (or super-superclass', and so on)
   implementation is returned.
   
   This function returns nil on failure. */
IMP XCFixinOverrideMethod(Class class, SEL selector, IMP newImplementation);
#define XCFixinOverrideMethodString(className, selector, newImplementation) XCFixinOverrideMethod(NSClassFromString(className), selector, newImplementation)