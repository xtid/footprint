import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:footprint/pages/more_info.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:cool_ui/cool_ui.dart';

import 'package:footprint/pages/category.dart';
import 'package:footprint/pages/detail.dart';
import 'package:footprint/pages/edit_page.dart';
import 'package:footprint/pages/user_edit.dart';

import 'package:footprint/widgets/left_drawer/left_drawer_avatar.dart';
import 'package:footprint/widgets/left_drawer/left_drawer_list_item.dart';
import 'package:footprint/widgets/list/list_image.dart';
import 'package:footprint/widgets/list/list_mask.dart';
import 'package:footprint/widgets/list/list_text.dart';
import 'package:footprint/widgets/list/list_empty_image.dart';
import 'package:footprint/widgets/list/list_empty_mask.dart';
import 'package:footprint/widgets/list/list_empty_text.dart';
import 'package:footprint/widgets/common/smart_drawer.dart'; 

import 'package:footprint/api/dio_web.dart';
import 'package:footprint/model/category.dart';

import 'package:footprint/enum/left_drawer_nav.dart';


class Home extends StatefulWidget {

  final String id;
  final String name;

  Home({this.id, this.name});

  @override
  _HomeState createState() => _HomeState();
}

class _HomeState extends State<Home> {

  List<CategoryDetail> footprintList = new List<CategoryDetail>();

  bool isRefresh = false;

  String token = '';
  String userName = '';
  String avatar = '';
  String id = '';

  int pageNum = 0;

  @override
  void initState() { 
    super.initState();
    getFootprintList();
  }

  void getFootprintUserInfo() async {
    var sp = await SharedPreferences.getInstance();
    var tokenData = sp.getString('token');
    var userNameData = sp.getString('userName');    
    var avatarData = sp.getString('avatar');
    var idData = sp.getString('_id');
    print('初始化时');
    setState(() {
      token = tokenData;
      userName = userNameData;
      avatar = avatarData;
      id = idData;
    });
  }

  Future getFootprintList() async {
    DioWeb.getFootprintList(widget.id, pageNum, true)
      .then((data) { 
        if (data != null && data.length != 0) {
          setState(() {
            pageNum = pageNum + 1;
            footprintList.addAll(data);
          });
          getFootprintUserInfo();
        } 
      });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.name, style: TextStyle(color: Color(0xFFFFFFFF), fontSize: 16)),
        backgroundColor: Color(0xFF4abdcc),
        elevation: 0.8,
        leading: Builder(builder: (context) {
          return IconButton(
            icon: Image.asset('assets/img/menu.png', width: 18.0, height: 18.0),
            onPressed: () {
              Scaffold.of(context).openDrawer();
            }
          );
        })
      ),
      drawer: leftDrawer(context, widget.id, token, userName, avatar, getFootprintUserInfo, id, (result) {
        setState(() {
          if (result != null && result.length != 0) {
            setState(() {
              isRefresh = true;
              pageNum = 1;
              footprintList = result;
            });
          } else {
            Fluttertoast.showToast(
              msg: '没有更多数据啦',
              gravity: ToastGravity.CENTER,
              timeInSecForIosWeb: 1
            );
          }
        });
      }),
      body: lists(context, footprintList, token, userName, widget.id, widget.name, pageNum, getFootprintList, isRefresh, () {
        setState(() {
          isRefresh = false;
        });
      }),
      backgroundColor: Color(0xFFfbf7ed),
    );
  }
}

Widget leftDrawer(context, id, token, userName, avatar, getFootprintUserInfo, userId, callback) {
  return SmartDrawer(
    widthPercent: 0.5,
    child: Container(
      child: Padding(
        padding: EdgeInsets.only(left: 10.0, right: 10.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: <Widget>[
            Column(
              children: <Widget>[
                LeftDrawerAvatar(token: token, userName: userName, avatar: avatar),
                ListView.builder(
                  shrinkWrap: true,
                  itemCount: LeftDrawerNav.leftDrawerNavList[0].length,
                  itemBuilder: (BuildContext context, int index) {
                    return LeftDrawerListItem(
                      imgUrl: LeftDrawerNav.leftDrawerNavList[0][index],
                      text: LeftDrawerNav.leftDrawerNavList[1][index],
                      link: LeftDrawerNav.leftDrawerNavList[2][index],
                      callback: (link) {
                        if (link == 'userEdit' && (userId == null || userId == '')) {
                          Fluttertoast.showToast(
                            msg: '请先登录后在操作',
                            gravity: ToastGravity.CENTER,
                            timeInSecForIosWeb: 1
                          );
                          return;
                        } else {
                          Navigator.pop(context);
                          Navigator.of(context).push(MaterialPageRoute(
                            builder: (BuildContext context) {
                              switch (link) {
                                case 'footprint':
                                  return CategoryPage();
                                case 'userEdit':
                                  return UserEdit();
                                case 'moreInfo':
                                  return MoreInfo();
                                default:
                                  return CategoryPage();
                                  break;
                              }
                            }
                          ));
                        }
                      }
                    );
                  }
                )
              ],
            ),
            token != '' && token != null ? Container(
              margin: EdgeInsets.only(bottom: 44.0),
              child: InkWell(
                child: Container(
                  alignment: Alignment.center,
                  margin: EdgeInsets.only(top: 60.0),
                  width: 164.0,
                  height: 40.0,
                  decoration: BoxDecoration(
                    color: Color(0xFF4abdcc),
                    border: Border.all(
                      color: Colors.white,
                    )
                  ),
                  child: Text('注销登录', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w300, fontSize: 16.0)),
                ),
                onTap: () async {
                  Navigator.pop(context);
                  var voidCallback = showWeuiLoadingToast(context: context, message: Text('加载中'));
                  var flag = await DioWeb.loginOut();
                  if (flag) {
                    showWeuiSuccessToast(context: context, message: Text('注销成功'), closeDuration: Duration(milliseconds: 1000));
                    Future.delayed(Duration(milliseconds: 1000), () {
                      Navigator.of(context).push(MaterialPageRoute(
                        builder: (BuildContext context) {
                          return Home(id: '', name: '生活');
                        }
                      )); 
                    });
                  }
                  voidCallback();
                },
              )
            ) : Container()
          ],
        )  
      ),
      color: Color(0xFF4abdcc),
    )
  );
}

Widget lists(context, footprintList, token, userName, homeId, homeName, pageNum, getFootprintList, isRefresh, callback) {
  
  ScrollController controller = new ScrollController();

  controller.addListener(() {
    var maxScroll = controller.position.maxScrollExtent;
    var pixel = controller.position.pixels;
    if (maxScroll == pixel) {
      getFootprintList();
    }
  });

  if (isRefresh) {   
    Future.delayed(Duration(seconds: 1), () {
      controller.animateTo(.0, duration: Duration(milliseconds: 200), curve: Curves.ease);
    });
    callback();
  }

  return Container(
    margin: EdgeInsets.only(top: 15.0),
    child: ListView.builder(
      itemCount: footprintList.length,
      itemBuilder: (BuildContext context, int index) {
        return InkWell(
          onTap: () {
            if (
              token != '' && 
              token != null && 
              userName != '' && 
              userName != null 
            ) {
              showCupertinoModalPopup (
                context: context,
                builder: (BuildContext context) {
                  return CupertinoActionSheet(
                    actions: <Widget>[
                      CupertinoActionSheetAction(
                        child: Text('编辑'),
                        onPressed: () {
                          Navigator.of(context).pop();
                          Navigator.of(context).push(MaterialPageRoute(
                            builder: (BuildContext context) {
                              return EditPage(listItem: footprintList[index], homeId: homeId, homeName: homeName);
                            }
                          ));
                        },
                        isDefaultAction: false,
                      ),
                      CupertinoActionSheetAction(
                        child: Text('查看详情'),
                        onPressed: () {
                          Navigator.of(context).pop();
                          Navigator.of(context).push(MaterialPageRoute(
                            builder: (BuildContext context) {
                              return Detail(listItem: footprintList[index]);
                            }
                          ));
                        },
                        isDestructiveAction: false,
                      ),
                    ],
                    cancelButton: CupertinoActionSheetAction(
                      child: Text('取消'),
                      onPressed: () {
                        Navigator.of(context).pop();
                      },
                    ),
                  );
                }
              );
            } else {
              Fluttertoast.showToast(
                msg: '请先登录后再操作',
                gravity: ToastGravity.CENTER,
                timeInSecForIosWeb: 1
              );
            }
          },
          child: Padding(
            padding: EdgeInsets.only(left: 15.0, right: 15.0, bottom: 15.0),
            child: Stack(
              children: <Widget>[
                footprintList.length != 0 && footprintList[index].imageUrl != '' ? 
                ListImage(imageUrl: footprintList[index].imageUrl) : 
                ListEmptyImage(),
                footprintList.length != 0 && footprintList[index].imageUrl != '' ? 
                ListMask() : 
                ListEmptyMask(),
                footprintList.length != 0 ? 
                ListText(categoryDetail: footprintList[index]) : 
                ListEmptyText()
              ],
            )
          )
        );
      },
      controller: controller,
    )
  ); 
}