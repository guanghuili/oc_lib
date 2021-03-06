//
//  UserModel.h
//  PMS
//
//  Created by ligh on 14/10/22.
//
//

#import "BaseModelObject.h"

//用户信息
@interface UserModel : BaseModelObject


@property (strong,nonatomic) NSString *userId; //用户id
@property (strong,nonatomic) NSString *brandId;//品牌id
@property (strong,nonatomic) NSString *userName;//用户昵称
@property (strong,nonatomic) NSString *password;//用户密码
@property (strong,nonatomic) NSString *realName;//姓名
@property (strong,nonatomic) NSString *sex;//性别
@property (strong,nonatomic) NSString *birthday;//生日
@property (strong,nonatomic) NSString *email;//
@property (strong,nonatomic) NSString *cellPhone;//手机号
@property (strong,nonatomic) NSString *telephone;//固话
@property (strong,nonatomic) NSString *province;//省份编号
@property (strong,nonatomic) NSString *city;//城市编号
@property (strong,nonatomic) NSString *district;//区编号
@property (strong,nonatomic) NSString *address;//地址
@property (strong,nonatomic) NSString *location;//定位
@property (strong,nonatomic) NSString *userPic;


-(NSString *) sexIconName;

@end
