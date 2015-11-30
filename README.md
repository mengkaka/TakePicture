# TakePicture
自定义相机、图片裁剪
## 简介
一个集成自定义相机、图片裁剪、及其他相关功能的Demo,每个模块都按控件封装好，内有详细注视，低耦合，可直接拿出可用；
## 自定义相机拍照（`K12CameraTakePictureView`）
1.继承自`UIView`，通过`AVCaptureSession`并且使用`AVCaptureVideoPreviewLayer`进行渲染；<br>
2.一行代码检测用户相机权限；<br>
3.方便控制摄像头闪光灯、和手电筒开启模式，还可以检测**当前摄像头周边环境**，太暗会以通知的方式发送出来；<br>
4.自定义显示**拍照参考线**、**相机对焦样式**、**焦距远近样式**；<br>
### 使用方法
```Objective-C
K12CameraTakePictureView *takePhotoView = [[K12CameraTakePictureView alloc]initWithFrame:self.view.bounds];
takePhotoView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
[self.view addSubview:takePhotoView];
```
### 监听周围环境
```Objective-C
[[NSNotificationCenter defaultCenter]addObserver:self selector:@selector(cameraTakePhotoViewAmbientDidChange:) name:K12CameraTakePictureViewAmbientDidChangeNotification object:takePhotoView];
```
## 图片裁剪功能（`K12PictureCuttingView`）
1.继承自`UIView`；<br>
2.可进行图片放大缩小、裁剪框放大缩小，裁剪图片的任意位置；<br>
3.根据裁剪框和图片大小动态调整可滑动区域，可在任何时候都能够裁剪到图片的任何位置；<br>
### 使用方法
```Objective-C
K12PictureCuttingView *cropView = [[K12PictureCuttingView alloc]initWithFrame:CGRectMake(0, 0, self.view.bounds.size.width, self.view.bounds.size.height-90)];
[cropView setCuttingImage:_image];
[self.view addSubview:cropView];
cropView.backgroundColor = [UIColor colorWithRed:16/255.0*3.52 green:32/255.0*3.52 blue:42/255.0*3.52 alpha:1.0];
cropView.defultCorpInset = UIEdgeInsetsMake(0, 50, 0, 50);
```
## 其他
### 动态键盘输入框（`K12TextInputManager`）
1.采用Autolayout动态根据文字长度布局输入框高度，超出固定行数以后自动向上滚动；
### 检测图片明暗度（`K12ImageLuminance`）
1.利用`Rx0.299+Gx0.587+Bx0.114`（参考http://b2cloud.com.au/tutorial/obtaining-luminosity-from-an-ios-camera/),计算出每个像素点的明暗度，在计算整张图片平均明暗度；
### 系统图片浏览查看（`K12PhotoLibraryController`）
1.可查看系统图片列表，并且点击查看大图，并且点击确认按钮，返回图片；
### 图片方向矫正（`UIImage+Orientation`）
1.可矫正或指定图片的方向


