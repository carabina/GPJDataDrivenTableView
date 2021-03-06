//
//  GPJDataDrivenTableView.h
//
//  Created by gongpengjun <frank.gongpengjun@gmail.com>
//

#import <UIKit/UIKit.h>

@interface GPJBaseData : NSObject
@property (nonatomic, copy) void (^didSelectAction)(id data);
- (CGFloat)cellHeight;
@end

@interface GPJBaseCell : UITableViewCell
@property (nonatomic, strong) id data;
- (void)configCell;
@end

@interface GPJDataDrivenTableView : UIView <UITableViewDelegate, UITableViewDataSource>
@property (nonatomic, weak, nullable) id <UITableViewDataSource> dataSource;
@property (nonatomic, weak, nullable) id <UITableViewDelegate> delegate;

@property (nonatomic, strong) UITableView *tableView;
@property (nonatomic, strong) NSArray     *dataArray;

- (instancetype)initWithFrame:(CGRect)frame;
- (void)reloadData;
- (void)reloadDataArray:(NSArray *)dataArray;
@end

@interface GPJDataDrivenTableView (DataCellMapping)
- (id)dataForIndexPath:(NSIndexPath *)indexPath;
- (Class)cellClassForIndexPath:(NSIndexPath *)indexPath;
- (CGFloat)heightForIndexPath:(NSIndexPath *)indexPath;
- (Class)cellClassForDataClass:(Class)dataClass;
@end
