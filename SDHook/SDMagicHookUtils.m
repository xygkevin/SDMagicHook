//
//  SDMagicHookUtils.m
//  SDMagicHook
//
//  Created by 高少东 on 2020/5/1.
//

#import "SDMagicHookUtils.h"
#import <pthread.h>
#import <objc/runtime.h>
#import <fishhook/fishhook.h>

Class _Nullable (*sd_original_setclass) (id _Nullable obj, Class _Nonnull cls);

Class _Nullable sd_magichook_set_calss(id _Nullable obj, Class _Nonnull cls) {

    if (sd_ifClassNameHasPrefix(cls, "NSKVONotifying_")) {
        Class originalClass = object_getClass(obj);
        if (sd_ifClassIsSDMagicClass(originalClass)) {
            return originalClass;
        } else {
            return sd_original_setclass(obj, cls);
        }
    } else {
        return sd_original_setclass(obj, cls);
    }
}

bool sd_ifClassNameHasPrefix(Class cls, const char *prefix) {
    const char *clsCStrName = class_getName(cls);
    void *startPos = strstr(clsCStrName, prefix);
    return startPos && startPos == clsCStrName;
}

bool sd_ifClassIsSDMagicClass(Class cls) {
    return sd_ifClassNameHasPrefix(cls, "SDMagicHook_");
}

NSString* createSelHeaderString(NSString *str, int index) {
    return [NSString stringWithFormat:@"__%d_%@", index, str];
}

SEL createSel(SEL sel, NSString *str) {
    NSString *originalSelStr = NSStringFromSelector(sel);
    NSString *newSelStr = [NSString stringWithFormat:@"%@_SD_%@", str, originalSelStr];
    return NSSelectorFromString(newSelStr);
}

SEL createSelA(SEL sel, int index, NSString *flag) {
    NSString *header = [NSString stringWithFormat:@"A_%@", flag];
    return createSel(sel, createSelHeaderString(header, index));
}

SEL createSelB(SEL sel, int index, NSString *flag) {
    NSString *header = [NSString stringWithFormat:@"B_%@", flag];
    return createSel(sel, createSelHeaderString(header, index));
}

NSString* currentThreadTag() {
    mach_port_t machTID = pthread_mach_thread_np(pthread_self());
    return [NSString stringWithFormat:@"%d", machTID];
}

NSMutableDictionary *threadStoredDictForEntry(NSString *entry) {
    NSMutableDictionary *res = [[NSThread currentThread].threadDictionary valueForKey:entry];
    if (!res) {
        res = [NSMutableDictionary new];
        [[NSThread currentThread].threadDictionary setValue:res forKey:entry];
    }
    return res;
}

NSString *entryForThreadStoredDict(const NSString *const key, NSString *className) {
    return [NSString stringWithFormat:@"%@-%@", key, className];
}

NSMutableDictionary *threadStoredDict(const NSString *const key, NSString *className) {
    return threadStoredDictForEntry(entryForThreadStoredDict(key, className));
}

@implementation SDMagicHookUtils

+ (void)hookSetClassFuncJustOnce {
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        rebind_symbols((struct rebinding[1]){{"object_setClass", sd_magichook_set_calss, (void *)&sd_original_setclass}}, 1);
    });
}

@end
