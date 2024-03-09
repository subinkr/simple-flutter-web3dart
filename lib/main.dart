import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart';
import 'package:untitled/slider_widget.dart';
import 'package:web3dart/web3dart.dart';
import 'package:velocity_x/velocity_x.dart';

void main() async {
  await dotenv.load(fileName: "assets/config/.env");

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      home: const MyHomePage(title: 'PKCoin'),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key, required this.title});

  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  late Client httpClient;
  late Web3Client ethClient;
  late bool data;
  EthPrivateKey credentials = EthPrivateKey.fromHex(dotenv.env['PK']!);
  int myAmount = 0;
  var myData = BigInt.from(0);

  @override
  void initState() {
    super.initState();
    httpClient = Client();
    ethClient = Web3Client(
      'https://sepolia.infura.io/v3/5bd0698767b84a6f95830ed39ca6b4d6',
      httpClient,
    );
    getBalance();
    // Timer.periodic(const Duration(seconds: 5), (timer) async {
    //   getBalance();
    // });
  }

  Future<DeployedContract> loadContract() async {
    String abi = await rootBundle.loadString('assets/abi/abi.json');
    String contractAddress = "0x6E2f836Dd2Ea1f23621bCe869771BC111A2Fb372";

    final contract = DeployedContract(ContractAbi.fromJson(abi, "PKCoin"),
        EthereumAddress.fromHex(contractAddress));

    return contract;
  }

  Future<List<dynamic>> query(String functionName, List<dynamic> args) async {
    final contract = await loadContract();
    final ethFunction = contract.function(functionName);
    final result = await ethClient.call(
      contract: contract,
      function: ethFunction,
      params: args,
    );

    return result;
  }

  Future<void> getBalance() async {
    // EthereumAddress address = EthereumAddress.fromHex(targetAddress);
    setState(() {
      data = false;
    });

    List<dynamic> result = await query('getBalance', []);
    myData = result[0];

    setState(() {
      data = true;
    });
  }

  Future<DeployedContract> submit(
      String functionName, List<dynamic> args) async {
    setState(() {
      data = false;
    });


    DeployedContract contract = await loadContract();
    final ethFunction = contract.function(functionName);
    final result = await ethClient.sendTransaction(
      credentials,
      Transaction.callContract(
        contract: contract,
        function: ethFunction,
        parameters: args,
      ),
      chainId: 11155111,
      // fetchChainIdFromNetworkId: true,
    );

    return contract;
  }

  Future<void> sendCoin() async {
    final bigAmount = BigInt.from(myAmount);
    final contract = await submit("depositBalance", [bigAmount]);
    final depositEvent = contract.event("Deposit");

    ethClient
        .events(FilterOptions.events(contract: contract, event: depositEvent))
        .take(1)
        .listen((event) {
      final decoded = depositEvent.decodeResults(event.topics!, event.data!);

      myData = decoded[0] as BigInt;

      setState(() {
        data = true;
      });
    });
  }

  Future<void> withdrawCoin() async {
    var bigAmount = BigInt.from(myAmount);
    var contract = await submit("withdrawBalance", [bigAmount]);
    final withdrawEvent = contract.event("Withdraw");

    ethClient
        .events(FilterOptions.events(contract: contract, event: withdrawEvent))
        .take(1)
        .listen((event) {
      final decoded = withdrawEvent.decodeResults(event.topics!, event.data!);

      myData = decoded[0] as BigInt;

      setState(() {
        data = true;
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Vx.gray300,
      body: ZStack(
        [
          VxBox()
              .blue600
              .size(context.screenWidth, context.percentHeight * 30)
              .make(),
          VStack(
            [
              (context.percentHeight * 10).heightBox,
              "My wallet".text.xl4.white.bold.center.makeCentered().py16(),
              (context.percentHeight * 5).heightBox,
              VxBox(
                      child: VStack([
                "Balance".text.gray700.xl2.semiBold.makeCentered(),
                10.heightBox,
                data
                    ? "\$$myData".text.bold.xl6.makeCentered()
                    : "\$$myData".text.bold.xl6.makeCentered().shimmer()
              ]))
                  .p16
                  .white
                  .size(context.screenWidth, context.percentHeight * 18)
                  .rounded
                  .shadowXl
                  .make()
                  .p16(),
              30.heightBox,
              SliderExample(finalVal: (value) {
                myAmount = value.round();
              }),
              HStack(
                [
                  IconButton(
                    style: IconButton.styleFrom(backgroundColor: Colors.blue),
                    onPressed: () {
                      getBalance();
                    },
                    icon: const Icon(
                      Icons.refresh,
                      color: Colors.white,
                      size: 64.0,
                    ),
                  ),
                  IconButton(
                    style: IconButton.styleFrom(backgroundColor: Colors.green),
                    onPressed: () {
                      sendCoin();
                    },
                    icon: const Icon(
                      Icons.call_made_outlined,
                      color: Colors.white,
                      size: 64.0,
                    ),
                  ),
                  IconButton(
                    style: IconButton.styleFrom(backgroundColor: Colors.red),
                    onPressed: () {
                      withdrawCoin();
                    },
                    icon: const Icon(
                      Icons.call_received_outlined,
                      color: Colors.white,
                      size: 64.0,
                    ),
                  ),
                ],
                alignment: MainAxisAlignment.spaceAround,
                axisSize: MainAxisSize.max,
              ).p16(),
            ],
          )
        ],
      ),
    );
  }
}
