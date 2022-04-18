/* Autogenerated file. Do not edit manually. */
/* tslint:disable */
/* eslint-disable */

import { Signer, utils, Contract, ContractFactory, Overrides } from "ethers";
import { Provider, TransactionRequest } from "@ethersproject/providers";
import type {
  EvaFlowChecker,
  EvaFlowCheckerInterface,
} from "../EvaFlowChecker";

const _abi = [
  {
    inputs: [
      {
        internalType: "address",
        name: "_config",
        type: "address",
      },
    ],
    stateMutability: "nonpayable",
    type: "constructor",
  },
  {
    inputs: [
      {
        internalType: "uint256",
        name: "keepbotId",
        type: "uint256",
      },
      {
        internalType: "uint256",
        name: "checkGasLimit",
        type: "uint256",
      },
      {
        internalType: "bytes",
        name: "checkdata",
        type: "bytes",
      },
      {
        internalType: "uint256",
        name: "lastMoveTime",
        type: "uint256",
      },
      {
        internalType: "enum KeepNetWork",
        name: "keepNetWork",
        type: "uint8",
      },
    ],
    name: "check",
    outputs: [
      {
        internalType: "bool",
        name: "needExec",
        type: "bool",
      },
      {
        internalType: "bytes",
        name: "execData",
        type: "bytes",
      },
    ],
    stateMutability: "view",
    type: "function",
  },
  {
    inputs: [],
    name: "checkGasLimitMin",
    outputs: [
      {
        internalType: "uint32",
        name: "",
        type: "uint32",
      },
    ],
    stateMutability: "view",
    type: "function",
  },
  {
    inputs: [],
    name: "config",
    outputs: [
      {
        internalType: "contract IEvabaseConfig",
        name: "",
        type: "address",
      },
    ],
    stateMutability: "view",
    type: "function",
  },
];

const _bytecode =
  "0x608060405234801561001057600080fd5b5060405161111238038061111283398101604081905261002f9161009d565b6001600160a01b0381166100785760405162461bcd60e51b815260206004820152600c60248201526b0c2c8c8cae6e640d2e64060f60a31b604482015260640160405180910390fd5b600080546001600160a01b0319166001600160a01b03929092169190911790556100cb565b6000602082840312156100ae578081fd5b81516001600160a01b03811681146100c4578182fd5b9392505050565b611038806100da6000396000f3fe608060405234801561001057600080fd5b50600436106100415760003560e01c8063506b733614610046578063635281fc1461006957806379502c551461008a575b600080fd5b61004f619c4081565b60405163ffffffff90911681526020015b60405180910390f35b61007c610077366004610cc2565b6100b5565b604051610060929190610e4b565b60005461009d906001600160a01b031681565b6040516001600160a01b039091168152602001610060565b6000606060008060009054906101000a90046001600160a01b03166001600160a01b031663f23062606040518163ffffffff1660e01b815260040160206040518083038186803b15801561010857600080fd5b505afa15801561011c573d6000803e3d6000fd5b505050506040513d601f19601f820116820180604052508101906101409190610d64565b6000805460405163055c2f8760e41b815292935090916001600160a01b03909116906355c2f87090610176908890600401610e81565b60206040518083038186803b15801561018e57600080fd5b505afa1580156101a2573d6000803e3d6000fd5b505050506040513d601f19601f820116820180604052508101906101c69190610d64565b905060008060009054906101000a90046001600160a01b03166001600160a01b031663d8de65876040518163ffffffff1660e01b815260040160206040518083038186803b15801561021757600080fd5b505afa15801561022b573d6000803e3d6000fd5b505050506040513d601f19601f8201168201806040525081019061024f9190610b57565b6001600160a01b0316638a8b49016040518163ffffffff1660e01b815260040160206040518083038186803b15801561028757600080fd5b505afa15801561029b573d6000803e3d6000fd5b505050506040513d601f19601f820116820180604052508101906102bf9190610caa565b905060006102cd8289610309565b90506000806102e5848663ffffffff168f8987610393565b915091506102f58282868e6104f2565b975097505050505050509550959350505050565b6000600a6103178342610f44565b1061035357604080514260208201528491016040516020818303038152906040528051906020012060001c61034c9190610fa6565b905061038d565b828260405160200161036791815260200190565b6040516020818303038152906040528051906020012060001c61038a9190610fa6565b90505b92915050565b6000806000861180156103a65750600087115b80156103b25750600085115b6103f05760405162461bcd60e51b81526004016103e7906020808252600490820152630677420360e41b604082015260600190565b60405180910390fd5b600086888161040f57634e487b7160e01b600052601260045260246000fd5b049050600087898161043157634e487b7160e01b600052601260045260246000fd5b0690508015610441576001909101905b63ffffffff86168211801561045a578663ffffffff1692505b82600189030286019450828802860193508985106104ca5789850394508984039350858511156104c5578985816104a157634e487b7160e01b600052601260045260246000fd5b0694508984816104c157634e487b7160e01b600052601260045260246000fd5b0693505b6104e5565b898411156104e55760018a85030393508584106104e5578593505b5050509550959350505050565b60006060600080606080888a1115610608578861050f8b8a610f44565b6105199190610f2c565b610524906001610f2c565b92508267ffffffffffffffff81111561054d57634e487b7160e01b600052604160045260246000fd5b604051908082528060200260200182016040528015610576578160200160208202803683370190505b5091508267ffffffffffffffff8111156105a057634e487b7160e01b600052604160045260246000fd5b6040519080825280602002602001820160405280156105d357816020015b60608152602001906001900390816105be5790505b5090506105e48a8984848b896106fb565b90955090925090506105fb60008a84848b896106fb565b90955090925090506106d6565b6106128a8a610f44565b92508267ffffffffffffffff81111561063b57634e487b7160e01b600052604160045260246000fd5b604051908082528060200260200182016040528015610664578160200160208202803683370190505b5091508267ffffffffffffffff81111561068e57634e487b7160e01b600052604160045260246000fd5b6040519080825280602002602001820160405280156106c157816020015b60608152602001906001900390816106ac5790505b5090506106d28a8a84848b896106fb565b5050505b8151156106e257600195505b6106ec8282610a8f565b94505050505094509492505050565b606060008181895b89811015610a775760005a905060008060009054906101000a90046001600160a01b03166001600160a01b031663d8de65876040518163ffffffff1660e01b815260040160206040518083038186803b15801561075f57600080fd5b505afa158015610773573d6000803e3d6000fd5b505050506040513d601f19601f820116820180604052508101906107979190610b57565b6001600160a01b0316636fd43d0f846040518263ffffffff1660e01b81526004016107c491815260200190565b60206040518083038186803b1580156107dc57600080fd5b505afa1580156107f0573d6000803e3d6000fd5b505050506040513d601f19601f820116820180604052508101906108149190610caa565b90508015610a6257600080546040805163d8de658760e01b8152905183926001600160a01b03169163d8de6587916004808301926020929190829003018186803b15801561086157600080fd5b505afa158015610875573d6000803e3d6000fd5b505050506040513d601f19601f820116820180604052508101906108999190610b57565b6001600160a01b03166308c49b8d846040518263ffffffff1660e01b81526004016108c691815260200190565b60006040518083038186803b1580156108de57600080fd5b505afa1580156108f2573d6000803e3d6000fd5b505050506040513d6000823e601f3d908101601f1916820160405261091a9190810190610bd7565b608001516001600160a01b031663c64b3bb58c6040518263ffffffff1660e01b81526004016109499190610e6e565b60006040518083038186803b15801561096157600080fd5b505afa158015610975573d6000803e3d6000fd5b505050506040513d6000823e601f3d908101601f1916820160405261099d9190810190610b71565b9150915060005a9050806109b18689610f2c565b6109bb9190610f44565b9650621e84808711806109cf5750619c4081105b156109e9578d8b8e99509950995050505050505050610a83565b8215610a5e57838e8c6109fb81610f8b565b9d5081518110610a1b57634e487b7160e01b600052603260045260246000fd5b6020908102919091010152818d8c610a3281610f8b565b9d5081518110610a5257634e487b7160e01b600052603260045260246000fd5b60200260200101819052505b5050505b50508080610a6f90610f8b565b915050610703565b50878588935093509350505b96509650969350505050565b60608282604051602001610aa4929190610db4565b604051602081830303815290604052905092915050565b6000610ace610ac984610f04565b610ed3565b9050828152838383011115610ae257600080fd5b610af0836020830184610f5b565b9392505050565b80516001600160a01b0381168114610b0e57600080fd5b919050565b805160068110610b0e57600080fd5b8035610b0e81610ff2565b8051610b0e81610ff2565b600082601f830112610b48578081fd5b61038a83835160208501610abb565b600060208284031215610b68578081fd5b61038a82610af7565b60008060408385031215610b83578081fd5b82518015158114610b92578182fd5b602084015190925067ffffffffffffffff811115610bae578182fd5b8301601f81018513610bbe578182fd5b610bcd85825160208401610abb565b9150509250929050565b600060208284031215610be8578081fd5b815167ffffffffffffffff80821115610bff578283fd5b908301906101008286031215610c13578283fd5b610c1b610ea9565b610c2483610b13565b8152610c3260208401610b2d565b6020820152610c4360408401610af7565b6040820152610c5460608401610af7565b6060820152610c6560808401610af7565b608082015260a083015160a082015260c083015160c082015260e083015182811115610c8f578485fd5b610c9b87828601610b38565b60e08301525095945050505050565b600060208284031215610cbb578081fd5b5051919050565b600080600080600060a08688031215610cd9578081fd5b8535945060208601359350604086013567ffffffffffffffff811115610cfd578182fd5b8601601f81018813610d0d578182fd5b8035610d1b610ac982610f04565b818152896020838501011115610d2f578384fd5b8160208401602083013790810160200183905293505060608601359150610d5860808701610b22565b90509295509295909350565b600060208284031215610d75578081fd5b815163ffffffff81168114610af0578182fd5b60008151808452610da0816020860160208601610f5b565b601f01601f19169290920160200192915050565b604080825283519082018190526000906020906060840190828701845b82811015610ded57815184529284019290840190600101610dd1565b50505083810382850152845180825282820190600581901b83018401878501865b83811015610e3c57601f19868403018552610e2a838351610d88565b94870194925090860190600101610e0e565b50909998505050505050505050565b8215158152604060208201526000610e666040830184610d88565b949350505050565b60208152600061038a6020830184610d88565b6020810160048310610ea357634e487b7160e01b600052602160045260246000fd5b91905290565b604051610100810167ffffffffffffffff81118282101715610ecd57610ecd610fdc565b60405290565b604051601f8201601f1916810167ffffffffffffffff81118282101715610efc57610efc610fdc565b604052919050565b600067ffffffffffffffff821115610f1e57610f1e610fdc565b50601f01601f191660200190565b60008219821115610f3f57610f3f610fc6565b500190565b600082821015610f5657610f56610fc6565b500390565b60005b83811015610f76578181015183820152602001610f5e565b83811115610f85576000848401525b50505050565b6000600019821415610f9f57610f9f610fc6565b5060010190565b600082610fc157634e487b7160e01b81526012600452602481fd5b500690565b634e487b7160e01b600052601160045260246000fd5b634e487b7160e01b600052604160045260246000fd5b60048110610fff57600080fd5b5056fea2646970667358221220d2a9884cd5b21701e993a1d6518d2dbfc044e8e3f486cd4d04d7fb1d4d512bdf64736f6c63430008040033";

export class EvaFlowChecker__factory extends ContractFactory {
  constructor(
    ...args: [signer: Signer] | ConstructorParameters<typeof ContractFactory>
  ) {
    if (args.length === 1) {
      super(_abi, _bytecode, args[0]);
    } else {
      super(...args);
    }
  }

  deploy(
    _config: string,
    overrides?: Overrides & { from?: string | Promise<string> }
  ): Promise<EvaFlowChecker> {
    return super.deploy(_config, overrides || {}) as Promise<EvaFlowChecker>;
  }
  getDeployTransaction(
    _config: string,
    overrides?: Overrides & { from?: string | Promise<string> }
  ): TransactionRequest {
    return super.getDeployTransaction(_config, overrides || {});
  }
  attach(address: string): EvaFlowChecker {
    return super.attach(address) as EvaFlowChecker;
  }
  connect(signer: Signer): EvaFlowChecker__factory {
    return super.connect(signer) as EvaFlowChecker__factory;
  }
  static readonly bytecode = _bytecode;
  static readonly abi = _abi;
  static createInterface(): EvaFlowCheckerInterface {
    return new utils.Interface(_abi) as EvaFlowCheckerInterface;
  }
  static connect(
    address: string,
    signerOrProvider: Signer | Provider
  ): EvaFlowChecker {
    return new Contract(address, _abi, signerOrProvider) as EvaFlowChecker;
  }
}
