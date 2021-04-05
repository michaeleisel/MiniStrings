#import "MNSMiniStrings.h"

@implementation MNSMiniStrings

static NSDictionary <NSString *, NSString *> *sKeyToString = nil;

+ (id)_jsonForPath:(NSString *)path
{
    NSURL *url = [[NSBundle mainBundle] URLForResource:path withExtension:nil];
    if (!url) {
        return nil;
    }
    NSData *data = [NSData dataWithContentsOfURL:url];
    return [NSJSONSerialization JSONObjectWithData:data options:0 error:nil];
}

+ (NSDictionary <NSString *, NSString *> *)_createKeyToString
{
    // Note that the preferred list does seem to at least include the development region as a fallback if there aren't
    // any other languages
    NSString *bestLocalization = [[[NSBundle mainBundle] preferredLocalizations] firstObject];
    if (!bestLocalization) {
        return @{};
    }
    NSString *valuesPath = [NSString stringWithFormat:@"localization/%@.json", bestLocalization];
    NSArray <id> *values = [self _jsonForPath:valuesPath];

    NSArray <NSString *> *keys = [self _jsonForPath:@"localization/keys.json"];

    NSMutableDictionary <NSString *, NSString *> *keyToString = [NSMutableDictionary dictionary];
    NSInteger count = keys.count;
    for (NSInteger i = 0; i < count; i++) {
        id value = values[i];
        if (value == [NSNull null]) {
            continue;
        }
        NSString *key = keys[i];
        keyToString[key] = value;
    }
    return [keyToString copy];
}

+ (NSString *)stringForKey:(NSString *)key
{
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        sKeyToString = [self _createKeyToString];
    });
    // Haven't tested with CFBundleAllowMixedLocalizations set to YES, although it seems like that'd be handled by the
    // NSLocalizedString fallback
    return sKeyToString[key] ?: NSLocalizedString(key, @"");
}

@end
