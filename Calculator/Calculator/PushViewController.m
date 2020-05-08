//
//  PushViewController.m
//  Calculator
//
//  Created by Max on 2019/1/28.
//  Copyright © 2019 net.qdating. All rights reserved.
//

#import "PushViewController.h"
#import "TestCollectionViewCell.h"

@interface PushViewController ()
@property IBOutlet UICollectionView *colectionView;
@end

@implementation PushViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    
    UINib *nib = [UINib nibWithNibName:[TestCollectionViewCell cellIdentifier] bundle:[NSBundle mainBundle]];
    [self.colectionView registerNib:nib forCellWithReuseIdentifier:[TestCollectionViewCell cellIdentifier]];
    
    [self.colectionView reloadData];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section {
    return 1;
}

- (UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath {
    UICollectionViewCell *cell = [collectionView dequeueReusableCellWithReuseIdentifier:[TestCollectionViewCell cellIdentifier] forIndexPath:indexPath];
    return cell;
}

- (void)collectionView:(UICollectionView *)collectionView didHighlightItemAtIndexPath:(NSIndexPath *)indexPath {
    UICollectionViewCell *cell = [collectionView cellForItemAtIndexPath:indexPath];
    cell.backgroundColor = [UIColor redColor];
}

- (void)collectionView:(UICollectionView *)collectionView didUnhighlightItemAtIndexPath:(NSIndexPath *)indexPath {
    UICollectionViewCell *cell = [collectionView cellForItemAtIndexPath:indexPath];
    cell.backgroundColor = [UIColor blueColor];
}

- (BOOL)collectionView:(UICollectionView *)collectionView shouldHighlightItemAtIndexPath:(NSIndexPath *)indexPath {
    return YES;
}

@end
