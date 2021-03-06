//
//  GPJDataDrivenTableView.m
//
//  Created by gongpengjun <frank.gongpengjun@gmail.com>
//

#import "GPJDataDrivenTableView.h"
#import <objc/runtime.h>

#define kDefaultCellHeight 44.0f

@implementation GPJBaseData

@synthesize didSelectAction;

- (CGFloat)cellHeight;
{
    return kDefaultCellHeight;
}

@end

@interface GPJBaseCell ()
+ (NSString *)GPJReuseIdentifier; // cell reuse identifier
@end

@implementation GPJBaseCell

+ (NSString *)GPJReuseIdentifier;
{
    return NSStringFromClass([self class]);
}

- (void)setData:(id)data
{
    _data = data;
    [self configCell];
}

- (void)configCell;
{
    // do nothing
}

@end

@implementation GPJDataDrivenTableView

- (void)setDataSource:(id<UITableViewDataSource>)dataSource
{
    _dataSource = dataSource;
    // force UITableView to re-query dataSource's methods
    self.tableView.dataSource = nil; self.tableView.dataSource = self;
}

- (void)setDelegate:(id<UITableViewDelegate>)delegate
{
    _delegate = delegate;
    // force UITableView to re-query delegate's methods
    self.tableView.delegate = nil; self.tableView.delegate = self;
}

#pragma mark - Life Cycle

- (void)dealloc;
{
    _tableView.delegate = nil;
    _tableView.dataSource = nil;
}

- (instancetype)initWithFrame:(CGRect)frame;
{
    self = [super initWithFrame:frame];
    if(self) {
        self.tableView = [[UITableView alloc] initWithFrame:self.bounds style:UITableViewStylePlain];
        [self addSubview:self.tableView];
        self.tableView.delegate = self;
        self.tableView.dataSource = self;
    }
    return self;
}

- (void)layoutSubviews;
{
    [super layoutSubviews];
    self.tableView.frame = self.bounds;
}

- (void)reloadData;
{
    [self.tableView reloadData];
}

- (void)reloadDataArray:(NSArray *)dataArray;
{
    self.dataArray = dataArray;
    [self.tableView reloadData];
}

#pragma mark - Data to Cell Mapping

- (NSInteger)sectionCount
{
    return 1;
}

- (NSInteger)rowCountInSection:(NSInteger)section;
{
    return self.dataArray.count;
}

- (id)dataForIndexPath:(NSIndexPath *)indexPath;
{
    if(0 <= indexPath.row && indexPath.row < self.dataArray.count)
        return [self.dataArray objectAtIndex:indexPath.row];
    else
        return nil;
}

- (Class)cellClassForIndexPath:(NSIndexPath *)indexPath;
{
    id data = [self dataForIndexPath:indexPath];
    Class cellClass = [self cellClassForDataClass:[data class]];
    return cellClass;
}

- (NSString *)reuseIdentifierForIndexPath:(NSIndexPath *)indexPath;
{
    return [[self cellClassForIndexPath:indexPath] GPJReuseIdentifier];
}

- (CGFloat)heightForIndexPath:(NSIndexPath *)indexPath;
{
    id data  = [self dataForIndexPath:indexPath];
    if ([data isKindOfClass:[GPJBaseData class]]) {
        return [data cellHeight];
    } else {
        return kDefaultCellHeight;
    }
}

#pragma mark - Data -> Cell name mapping

- (Class)cellClassForDataClass:(Class)dataClass;
{
    NSString *dataClassName = NSStringFromClass(dataClass);
    NSString *cellClassName = nil;
    if ([dataClassName hasSuffix:@"Data"]) {
        cellClassName = [[dataClassName substringToIndex:dataClassName.length-@"Data".length] stringByAppendingString:@"Cell"];
    }
    Class cellClass = NSClassFromString(cellClassName);
    NSAssert(cellClass, @"fatal error: NO cell class '%@' for data class '%@'",cellClassName,dataClassName);
    return cellClass;
}

#pragma mark - UITableViewDataSource

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return [self sectionCount];
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return [self rowCountInSection:section];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    NSString *identifier = [self reuseIdentifierForIndexPath:indexPath];
    Class     cellClass  = [self cellClassForIndexPath:indexPath];
    [_tableView registerClass:cellClass forCellReuseIdentifier:identifier];
    // the dequeue method guarantees a cell is returned and resized properly, assuming identifier is registered
    GPJBaseCell *cell = [_tableView dequeueReusableCellWithIdentifier:identifier forIndexPath:indexPath];
    cell.data = [self dataForIndexPath:indexPath];
    return cell;
}

#pragma mark - UITableViewDelegate

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath;
{
    return [self heightForIndexPath:indexPath];
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath;
{
    id data = [self dataForIndexPath:indexPath];
    if (![data isKindOfClass:[GPJBaseData class]])
        return;
    GPJBaseData *baseData = (GPJBaseData *)data;
    if (baseData.didSelectAction) {
        baseData.didSelectAction(data);
    }
}

@end

#pragma mark -

@implementation GPJDataDrivenTableView (MessageForward)

- (BOOL)shouldForwardSelectorToDataSource:(SEL)aSelector
{
    // Only forward the selector to dataSource if it's part of the UITableViewDataSource protocol.
    struct objc_method_description description = protocol_getMethodDescription(@protocol(UITableViewDataSource), aSelector, NO, YES);
    BOOL isSelectorInTableViewDataSource = (description.name != NULL && description.types != NULL);
    BOOL shouldForword = (isSelectorInTableViewDataSource && [self.dataSource respondsToSelector:aSelector]);
    return shouldForword;
}

- (BOOL)shouldForwardSelectorToDelegate:(SEL)aSelector
{
    // Only forward the selector to delegate if it's part of the UITableViewDelegate protocol.
    struct objc_method_description description = protocol_getMethodDescription(@protocol(UITableViewDelegate), aSelector, NO, YES);
    BOOL isSelectorInTableViewDelegate = (description.name != NULL && description.types != NULL);
    BOOL shouldForword = (isSelectorInTableViewDelegate && [self.delegate respondsToSelector:aSelector]);
    return shouldForword;
}

- (BOOL)respondsToSelector:(SEL)aSelector
{
    if ([self shouldForwardSelectorToDataSource:aSelector]) {
        return YES;
    }
    
    if ([self shouldForwardSelectorToDelegate:aSelector]) {
        return YES;
    }
    
    return [super respondsToSelector:aSelector];
}

- (BOOL)conformsToProtocol:(Protocol *)aProtocol
{
    if ([NSStringFromProtocol(aProtocol) isEqualToString:@"UITableViewDataSource"]) {
        return YES;
    }
    
    if ([NSStringFromProtocol(aProtocol) isEqualToString:@"UITableViewDelegate"]) {
        return YES;
    }
    
    return [super conformsToProtocol:aProtocol];
}

- (id)forwardingTargetForSelector:(SEL)aSelector
{
    if ([self shouldForwardSelectorToDataSource:aSelector]) {
        return self.dataSource;
    }
    
    if ([self shouldForwardSelectorToDelegate:aSelector]) {
        return self.delegate;
    }
    
    return [super forwardingTargetForSelector:aSelector];
}

@end
