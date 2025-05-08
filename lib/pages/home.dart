import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:shopping_app/pages/category_products.dart';
import 'package:shopping_app/pages/widget/support_widget.dart';
import 'package:shopping_app/services/database.dart';
import 'package:shopping_app/services/shared_pref.dart';

class Home extends StatefulWidget {
  const Home({super.key});

  @override
  State<Home> createState() => _HomeState();
}

class _HomeState extends State<Home> {
bool search=false;


  List categories = [
    "images/headphoneicon.png",
    "images/laptopicon.png",
    "images/watchicon.png",
    "images/tvicon.png",
  ];

  List Categoryname = [
    "Headphones",
    "Laptop",
    "Watch",
    "TV",
  ];

  var queryResultSet=[];
  var tempSearchStore=[];



  initiateSearch(value){
    if(value.length==0){
      setState(() {
        queryResultSet=[];
        tempSearchStore=[];
      });
    }
    setState(() {
      search = true;
    });

    var CapitalizedValue = value.substring(0,1).toUpperCase()+value.substring(1);
    if(queryResultSet.isEmpty && value.length==1){
      DatabaseMethods().search(value).then((QuerySnapshot docs){
        for(int i=0; i<docs.docs.length; ++i){
          queryResultSet.add(docs.docs[i].data());
        }
      });
    }else{
      tempSearchStore=[];
      queryResultSet.forEach((element){
        if(element['UpdateName'].startsWith(CapitalizedValue )){
          setState(() {
            tempSearchStore.add(element);
          });
        }
      });
    }
  }

  String? name, image;

  getthesharedpref() async {
    name = await SharedPreferenceHelper().getUserName();
    image = await SharedPreferenceHelper().getUserImage();
    setState(() {});
  }

  ontheload() async {
    await getthesharedpref();
    setState(() {});
  }

  @override
  void initState() {
    ontheload();
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xfff2f2f2),
      body: name == null?
           Center(child: CircularProgressIndicator())
          : Container(
              margin: EdgeInsets.only(top: 50.0, left: 20.0, right: 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text("Hey, " + name!,
                              style: AppWidget.boldTextFeildStyle()),
                          Text("Good Morning",
                              style: AppWidget.lightTextFeildStyle()),
                        ],
                      ),
                      ClipRRect(
                          borderRadius: BorderRadius.circular(20),
                          child: Image.asset(
                            "images/boy.jpg",
                            height: 70,
                            width: 70,
                            fit: BoxFit.cover,
                          )),
                    ],
                  ),
                  SizedBox(
                    height: 30,
                  ),
                  Container(
                    decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(10)),
                    width: MediaQuery.of(context).size.width,
                    child: TextField(
                      onChanged: (value){
                        initiateSearch(value);
                      },
                      decoration: InputDecoration(
                        border: InputBorder.none,
                        hintText: "Search Products",
                        hintStyle: AppWidget.lightTextFeildStyle(),
                        prefixIcon: Icon(
                          Icons.search,
                          color: Colors.black,
                        ),
                      ),
                    ),
                  ),
                  SizedBox(
                    height: 20,
                  ),
              search? ListView(
                padding: EdgeInsets.only(left: 10, right: 10),
                primary: false,
                shrinkWrap: true,
                children: tempSearchStore.map((element){
                  return buildResultCard(element);
                }).toList(),
              ):    Padding(
                    padding: const EdgeInsets.only(right: 20),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          "Categories",
                          style: AppWidget.semiboldTextFeildStyle(),
                        ),
                        Text(
                          "see all",
                          style: TextStyle(
                              color: Color(0xfffd6f3e),
                              fontSize: 18,
                              fontWeight: FontWeight.bold),
                        )
                      ],
                    ),
                  ),
                  SizedBox(
                    height: 20,
                  ),
                  Row(
                    children: [
                      Container(
                          height: 130,
                          padding: EdgeInsets.all(20),
                          margin: EdgeInsets.only(right: 20),
                          decoration: BoxDecoration(
                              color: Color(0xfffd6f3e),
                              borderRadius: BorderRadius.circular(10)),
                          child: Center(
                              child: Text(
                            "All",
                            style: TextStyle(
                                color: Colors.white,
                                fontSize: 20,
                                fontWeight: FontWeight.bold),
                          ))),
                      Expanded(
                        child: Container(
                          height: 130,
                          child: ListView.builder(
                              padding: EdgeInsets.zero,
                              itemCount: categories.length,
                              shrinkWrap: true,
                              scrollDirection: Axis.horizontal,
                              itemBuilder: (context, index) {
                                return CategoryTile(
                                    image: categories[index],
                                    name: Categoryname[index]);
                              }),
                        ),
                      ),
                    ],
                  ),
                  SizedBox(
                    height: 20,
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        "All Products",
                        style: AppWidget.semiboldTextFeildStyle(),
                      ),
                      Text(
                        "see all",
                        style: TextStyle(
                            color: Color(0xfffd6f3e),
                            fontSize: 18,
                            fontWeight: FontWeight.bold),
                      )
                    ],
                  ),
                  SizedBox(
                    height: 30,
                  ),
                  Container(
                    height: 240,
                    child: ListView(
                      shrinkWrap: true,
                      scrollDirection: Axis.horizontal,
                      children: [
                        Container(
                          margin: EdgeInsets.only(right: 20),
                          padding: EdgeInsets.symmetric(horizontal: 20),
                          decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(10)),
                          child: Column(
                            children: [
                              Image.asset(
                                "images/headphone2.png",
                                height: 150,
                                width: 150,
                                fit: BoxFit.cover,
                              ),
                              Text(
                                "Headphone",
                                style: AppWidget.semiboldTextFeildStyle(),
                              ),
                              SizedBox(
                                height: 10,
                              ),
                              Row(
                                children: [
                                  Text(
                                    "\$100",
                                    style: TextStyle(
                                        color: Color(0xfffd6f3e),
                                        fontSize: 20,
                                        fontWeight: FontWeight.bold),
                                  ),
                                  SizedBox(
                                    width: 50,
                                  ),
                                  Container(
                                      padding: EdgeInsets.all(5),
                                      decoration: BoxDecoration(
                                          color: Color(0xfffd6f3e),
                                          borderRadius:
                                              BorderRadius.circular(7)),
                                      child: Icon(
                                        Icons.add,
                                        color: Colors.white,
                                      ))
                                ],
                              )
                            ],
                          ),
                        ),
                        Container(
                          margin: EdgeInsets.only(right: 20),
                          padding: EdgeInsets.symmetric(horizontal: 20),
                          decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(10)),
                          child: Column(
                            children: [
                              Image.asset(
                                "images/watch2.png",
                                height: 150,
                                width: 150,
                                fit: BoxFit.cover,
                              ),
                              Text(
                                "Apple Watch   ",
                                style: AppWidget.semiboldTextFeildStyle(),
                              ),
                              SizedBox(
                                height: 10,
                              ),
                              Row(
                                children: [
                                  Text(
                                    "\$300",
                                    style: TextStyle(
                                        color: Color(0xfffd6f3e),
                                        fontSize: 20,
                                        fontWeight: FontWeight.bold),
                                  ),
                                  SizedBox(
                                    width: 50,
                                  ),
                                  Container(
                                      padding: EdgeInsets.all(5),
                                      decoration: BoxDecoration(
                                          color: Color(0xfffd6f3e),
                                          borderRadius:
                                              BorderRadius.circular(7)),
                                      child: Icon(
                                        Icons.add,
                                        color: Colors.white,
                                      ))
                                ],
                              )
                            ],
                          ),
                        ),
                        Container(
                          padding: EdgeInsets.symmetric(horizontal: 20),
                          decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(10)),
                          child: Column(
                            children: [
                              Image.asset(
                                "images/laptop2.png",
                                height: 150,
                                width: 150,
                                fit: BoxFit.cover,
                              ),
                              Text(
                                "Laptop",
                                style: AppWidget.semiboldTextFeildStyle(),
                              ),
                              SizedBox(
                                height: 10,
                              ),
                              Row(
                                children: [
                                  Text(
                                    "\$1000",
                                    style: TextStyle(
                                        color: Color(0xfffd6f3e),
                                        fontSize: 20,
                                        fontWeight: FontWeight.bold),
                                  ),
                                  SizedBox(
                                    width: 50,
                                  ),
                                  Container(
                                      padding: EdgeInsets.all(5),
                                      decoration: BoxDecoration(
                                          color: Color(0xfffd6f3e),
                                          borderRadius:
                                              BorderRadius.circular(7)),
                                      child: Icon(
                                        Icons.add,
                                        color: Colors.white,
                                      ))
                                ],
                              )
                            ],
                          ),
                        )
                      ],
                    ),
                  ),
                ],
              ),
            ),
    );
  }
  Widget buildResultCard(data){
    return Container(
      height: 100,
      child: Row(
        children: [
          Image.network(data["Image"], height: 50, width: 50, fit: BoxFit.cover,),
          Text(data["Name"],style: AppWidget.semiboldTextFeildStyle(),)
        ],
      ),
    );
  }
}

class CategoryTile extends StatelessWidget {
  String image, name;
  CategoryTile({required this.image, required this.name});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
            context,
            MaterialPageRoute(
                builder: (context) => CategoryProduct(category: name)));
      },
      child: Container(
        padding: EdgeInsets.all(20),
        margin: EdgeInsets.only(right: 20),
        decoration: BoxDecoration(
            color: Colors.white, borderRadius: BorderRadius.circular(10)),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Image.asset(
              image,
              height: 50,
              width: 50,
              fit: BoxFit.cover,
            ),
            Icon(Icons.arrow_forward)
          ],
        ),
      ),
    );
  }
  
}
