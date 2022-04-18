/* Autogenerated file. Do not edit manually. */
/* tslint:disable */
/* eslint-disable */

import {
  ethers,
  EventFilter,
  Signer,
  BigNumber,
  BigNumberish,
  PopulatedTransaction,
  BaseContract,
  ContractTransaction,
  Overrides,
  PayableOverrides,
  CallOverrides,
} from "ethers";
import { BytesLike } from "@ethersproject/bytes";
import { Listener, Provider } from "@ethersproject/providers";
import { FunctionFragment, EventFragment, Result } from "@ethersproject/abi";
import type { TypedEventFilter, TypedEvent, TypedListener } from "./common";

interface IEvaFlowControlerInterface extends ethers.utils.Interface {
  functions: {
    "addFundByUser(address,uint256,address)": FunctionFragment;
    "batchExecFlow(bytes,uint256)": FunctionFragment;
    "createEvaSafes(address)": FunctionFragment;
    "createFlow(string,uint8,bytes)": FunctionFragment;
    "destroyFlow(uint256)": FunctionFragment;
    "execFlow(uint256,bytes)": FunctionFragment;
    "getAllVaildFlowSize()": FunctionFragment;
    "getFlowMetas(uint256)": FunctionFragment;
    "getIndexVaildFlow(uint256)": FunctionFragment;
    "getSafes(address)": FunctionFragment;
    "getVaildFlowRange(uint256,uint256)": FunctionFragment;
    "pauseFlow(uint256)": FunctionFragment;
    "startFlow(uint256)": FunctionFragment;
    "updateFlow(uint256,string,bytes)": FunctionFragment;
    "withdrawFundByUser(address,uint256)": FunctionFragment;
    "withdrawPayment(address,uint256)": FunctionFragment;
  };

  encodeFunctionData(
    functionFragment: "addFundByUser",
    values: [string, BigNumberish, string]
  ): string;
  encodeFunctionData(
    functionFragment: "batchExecFlow",
    values: [BytesLike, BigNumberish]
  ): string;
  encodeFunctionData(
    functionFragment: "createEvaSafes",
    values: [string]
  ): string;
  encodeFunctionData(
    functionFragment: "createFlow",
    values: [string, BigNumberish, BytesLike]
  ): string;
  encodeFunctionData(
    functionFragment: "destroyFlow",
    values: [BigNumberish]
  ): string;
  encodeFunctionData(
    functionFragment: "execFlow",
    values: [BigNumberish, BytesLike]
  ): string;
  encodeFunctionData(
    functionFragment: "getAllVaildFlowSize",
    values?: undefined
  ): string;
  encodeFunctionData(
    functionFragment: "getFlowMetas",
    values: [BigNumberish]
  ): string;
  encodeFunctionData(
    functionFragment: "getIndexVaildFlow",
    values: [BigNumberish]
  ): string;
  encodeFunctionData(functionFragment: "getSafes", values: [string]): string;
  encodeFunctionData(
    functionFragment: "getVaildFlowRange",
    values: [BigNumberish, BigNumberish]
  ): string;
  encodeFunctionData(
    functionFragment: "pauseFlow",
    values: [BigNumberish]
  ): string;
  encodeFunctionData(
    functionFragment: "startFlow",
    values: [BigNumberish]
  ): string;
  encodeFunctionData(
    functionFragment: "updateFlow",
    values: [BigNumberish, string, BytesLike]
  ): string;
  encodeFunctionData(
    functionFragment: "withdrawFundByUser",
    values: [string, BigNumberish]
  ): string;
  encodeFunctionData(
    functionFragment: "withdrawPayment",
    values: [string, BigNumberish]
  ): string;

  decodeFunctionResult(
    functionFragment: "addFundByUser",
    data: BytesLike
  ): Result;
  decodeFunctionResult(
    functionFragment: "batchExecFlow",
    data: BytesLike
  ): Result;
  decodeFunctionResult(
    functionFragment: "createEvaSafes",
    data: BytesLike
  ): Result;
  decodeFunctionResult(functionFragment: "createFlow", data: BytesLike): Result;
  decodeFunctionResult(
    functionFragment: "destroyFlow",
    data: BytesLike
  ): Result;
  decodeFunctionResult(functionFragment: "execFlow", data: BytesLike): Result;
  decodeFunctionResult(
    functionFragment: "getAllVaildFlowSize",
    data: BytesLike
  ): Result;
  decodeFunctionResult(
    functionFragment: "getFlowMetas",
    data: BytesLike
  ): Result;
  decodeFunctionResult(
    functionFragment: "getIndexVaildFlow",
    data: BytesLike
  ): Result;
  decodeFunctionResult(functionFragment: "getSafes", data: BytesLike): Result;
  decodeFunctionResult(
    functionFragment: "getVaildFlowRange",
    data: BytesLike
  ): Result;
  decodeFunctionResult(functionFragment: "pauseFlow", data: BytesLike): Result;
  decodeFunctionResult(functionFragment: "startFlow", data: BytesLike): Result;
  decodeFunctionResult(functionFragment: "updateFlow", data: BytesLike): Result;
  decodeFunctionResult(
    functionFragment: "withdrawFundByUser",
    data: BytesLike
  ): Result;
  decodeFunctionResult(
    functionFragment: "withdrawPayment",
    data: BytesLike
  ): Result;

  events: {
    "FlowCreated(address,uint256,address)": EventFragment;
    "FlowDestroyed(address,uint256)": EventFragment;
    "FlowExecuted(address,uint256,bool,uint256,uint256,uint256)": EventFragment;
    "FlowPaused(address,uint256)": EventFragment;
    "FlowStart(address,uint256)": EventFragment;
    "FlowUpdated(address,uint256,address)": EventFragment;
    "SetMinConfig(address,address,address,uint64,uint64,uint16,uint16)": EventFragment;
  };

  getEvent(nameOrSignatureOrTopic: "FlowCreated"): EventFragment;
  getEvent(nameOrSignatureOrTopic: "FlowDestroyed"): EventFragment;
  getEvent(nameOrSignatureOrTopic: "FlowExecuted"): EventFragment;
  getEvent(nameOrSignatureOrTopic: "FlowPaused"): EventFragment;
  getEvent(nameOrSignatureOrTopic: "FlowStart"): EventFragment;
  getEvent(nameOrSignatureOrTopic: "FlowUpdated"): EventFragment;
  getEvent(nameOrSignatureOrTopic: "SetMinConfig"): EventFragment;
}

export type FlowCreatedEvent = TypedEvent<
  [string, BigNumber, string] & {
    user: string;
    _flowId: BigNumber;
    flowAdd: string;
  }
>;

export type FlowDestroyedEvent = TypedEvent<
  [string, BigNumber] & { user: string; _flowId: BigNumber }
>;

export type FlowExecutedEvent = TypedEvent<
  [string, BigNumber, boolean, BigNumber, BigNumber, BigNumber] & {
    user: string;
    _flowId: BigNumber;
    sucesss: boolean;
    payAmountByETH: BigNumber;
    payAmountByFeeToken: BigNumber;
    gasUsed: BigNumber;
  }
>;

export type FlowPausedEvent = TypedEvent<
  [string, BigNumber] & { user: string; _flowId: BigNumber }
>;

export type FlowStartEvent = TypedEvent<
  [string, BigNumber] & { user: string; _flowId: BigNumber }
>;

export type FlowUpdatedEvent = TypedEvent<
  [string, BigNumber, string] & {
    user: string;
    _flowId: BigNumber;
    flowAdd: string;
  }
>;

export type SetMinConfigEvent = TypedEvent<
  [string, string, string, BigNumber, BigNumber, number, number] & {
    user: string;
    feeRecived: string;
    feeToken: string;
    minGasFundForUser: BigNumber;
    minGasFundOneFlow: BigNumber;
    PPB: number;
    blockCountPerTurn: number;
  }
>;

export class IEvaFlowControler extends BaseContract {
  connect(signerOrProvider: Signer | Provider | string): this;
  attach(addressOrName: string): this;
  deployed(): Promise<this>;

  listeners<EventArgsArray extends Array<any>, EventArgsObject>(
    eventFilter?: TypedEventFilter<EventArgsArray, EventArgsObject>
  ): Array<TypedListener<EventArgsArray, EventArgsObject>>;
  off<EventArgsArray extends Array<any>, EventArgsObject>(
    eventFilter: TypedEventFilter<EventArgsArray, EventArgsObject>,
    listener: TypedListener<EventArgsArray, EventArgsObject>
  ): this;
  on<EventArgsArray extends Array<any>, EventArgsObject>(
    eventFilter: TypedEventFilter<EventArgsArray, EventArgsObject>,
    listener: TypedListener<EventArgsArray, EventArgsObject>
  ): this;
  once<EventArgsArray extends Array<any>, EventArgsObject>(
    eventFilter: TypedEventFilter<EventArgsArray, EventArgsObject>,
    listener: TypedListener<EventArgsArray, EventArgsObject>
  ): this;
  removeListener<EventArgsArray extends Array<any>, EventArgsObject>(
    eventFilter: TypedEventFilter<EventArgsArray, EventArgsObject>,
    listener: TypedListener<EventArgsArray, EventArgsObject>
  ): this;
  removeAllListeners<EventArgsArray extends Array<any>, EventArgsObject>(
    eventFilter: TypedEventFilter<EventArgsArray, EventArgsObject>
  ): this;

  listeners(eventName?: string): Array<Listener>;
  off(eventName: string, listener: Listener): this;
  on(eventName: string, listener: Listener): this;
  once(eventName: string, listener: Listener): this;
  removeListener(eventName: string, listener: Listener): this;
  removeAllListeners(eventName?: string): this;

  queryFilter<EventArgsArray extends Array<any>, EventArgsObject>(
    event: TypedEventFilter<EventArgsArray, EventArgsObject>,
    fromBlockOrBlockhash?: string | number | undefined,
    toBlock?: string | number | undefined
  ): Promise<Array<TypedEvent<EventArgsArray & EventArgsObject>>>;

  interface: IEvaFlowControlerInterface;

  functions: {
    addFundByUser(
      tokenAdress: string,
      amount: BigNumberish,
      user: string,
      overrides?: PayableOverrides & { from?: string | Promise<string> }
    ): Promise<ContractTransaction>;

    batchExecFlow(
      _data: BytesLike,
      gasLimit: BigNumberish,
      overrides?: Overrides & { from?: string | Promise<string> }
    ): Promise<ContractTransaction>;

    createEvaSafes(
      user: string,
      overrides?: Overrides & { from?: string | Promise<string> }
    ): Promise<ContractTransaction>;

    createFlow(
      flowName: string,
      keepNetWork: BigNumberish,
      flowCode: BytesLike,
      overrides?: PayableOverrides & { from?: string | Promise<string> }
    ): Promise<ContractTransaction>;

    destroyFlow(
      _flowId: BigNumberish,
      overrides?: Overrides & { from?: string | Promise<string> }
    ): Promise<ContractTransaction>;

    execFlow(
      _flowId: BigNumberish,
      _inputData: BytesLike,
      overrides?: Overrides & { from?: string | Promise<string> }
    ): Promise<ContractTransaction>;

    getAllVaildFlowSize(
      overrides?: CallOverrides
    ): Promise<[BigNumber] & { size: BigNumber }>;

    getFlowMetas(
      index: BigNumberish,
      overrides?: CallOverrides
    ): Promise<
      [
        [
          number,
          number,
          string,
          string,
          string,
          BigNumber,
          BigNumber,
          string
        ] & {
          flowStatus: number;
          keepNetWork: number;
          admin: string;
          lastKeeper: string;
          lastVersionflow: string;
          lastExecNumber: BigNumber;
          maxVaildBlockNumber: BigNumber;
          flowName: string;
        }
      ]
    >;

    getIndexVaildFlow(
      _index: BigNumberish,
      overrides?: CallOverrides
    ): Promise<[BigNumber] & { value: BigNumber }>;

    getSafes(user: string, overrides?: CallOverrides): Promise<[string]>;

    getVaildFlowRange(
      fromIndex: BigNumberish,
      endIndex: BigNumberish,
      overrides?: CallOverrides
    ): Promise<[BigNumber[]] & { arr: BigNumber[] }>;

    pauseFlow(
      _flowId: BigNumberish,
      overrides?: Overrides & { from?: string | Promise<string> }
    ): Promise<ContractTransaction>;

    startFlow(
      _flowId: BigNumberish,
      overrides?: Overrides & { from?: string | Promise<string> }
    ): Promise<ContractTransaction>;

    updateFlow(
      _flowId: BigNumberish,
      _flowName: string,
      flowCode: BytesLike,
      overrides?: Overrides & { from?: string | Promise<string> }
    ): Promise<ContractTransaction>;

    withdrawFundByUser(
      tokenAdress: string,
      amount: BigNumberish,
      overrides?: Overrides & { from?: string | Promise<string> }
    ): Promise<ContractTransaction>;

    withdrawPayment(
      tokenAdress: string,
      amount: BigNumberish,
      overrides?: Overrides & { from?: string | Promise<string> }
    ): Promise<ContractTransaction>;
  };

  addFundByUser(
    tokenAdress: string,
    amount: BigNumberish,
    user: string,
    overrides?: PayableOverrides & { from?: string | Promise<string> }
  ): Promise<ContractTransaction>;

  batchExecFlow(
    _data: BytesLike,
    gasLimit: BigNumberish,
    overrides?: Overrides & { from?: string | Promise<string> }
  ): Promise<ContractTransaction>;

  createEvaSafes(
    user: string,
    overrides?: Overrides & { from?: string | Promise<string> }
  ): Promise<ContractTransaction>;

  createFlow(
    flowName: string,
    keepNetWork: BigNumberish,
    flowCode: BytesLike,
    overrides?: PayableOverrides & { from?: string | Promise<string> }
  ): Promise<ContractTransaction>;

  destroyFlow(
    _flowId: BigNumberish,
    overrides?: Overrides & { from?: string | Promise<string> }
  ): Promise<ContractTransaction>;

  execFlow(
    _flowId: BigNumberish,
    _inputData: BytesLike,
    overrides?: Overrides & { from?: string | Promise<string> }
  ): Promise<ContractTransaction>;

  getAllVaildFlowSize(overrides?: CallOverrides): Promise<BigNumber>;

  getFlowMetas(
    index: BigNumberish,
    overrides?: CallOverrides
  ): Promise<
    [number, number, string, string, string, BigNumber, BigNumber, string] & {
      flowStatus: number;
      keepNetWork: number;
      admin: string;
      lastKeeper: string;
      lastVersionflow: string;
      lastExecNumber: BigNumber;
      maxVaildBlockNumber: BigNumber;
      flowName: string;
    }
  >;

  getIndexVaildFlow(
    _index: BigNumberish,
    overrides?: CallOverrides
  ): Promise<BigNumber>;

  getSafes(user: string, overrides?: CallOverrides): Promise<string>;

  getVaildFlowRange(
    fromIndex: BigNumberish,
    endIndex: BigNumberish,
    overrides?: CallOverrides
  ): Promise<BigNumber[]>;

  pauseFlow(
    _flowId: BigNumberish,
    overrides?: Overrides & { from?: string | Promise<string> }
  ): Promise<ContractTransaction>;

  startFlow(
    _flowId: BigNumberish,
    overrides?: Overrides & { from?: string | Promise<string> }
  ): Promise<ContractTransaction>;

  updateFlow(
    _flowId: BigNumberish,
    _flowName: string,
    flowCode: BytesLike,
    overrides?: Overrides & { from?: string | Promise<string> }
  ): Promise<ContractTransaction>;

  withdrawFundByUser(
    tokenAdress: string,
    amount: BigNumberish,
    overrides?: Overrides & { from?: string | Promise<string> }
  ): Promise<ContractTransaction>;

  withdrawPayment(
    tokenAdress: string,
    amount: BigNumberish,
    overrides?: Overrides & { from?: string | Promise<string> }
  ): Promise<ContractTransaction>;

  callStatic: {
    addFundByUser(
      tokenAdress: string,
      amount: BigNumberish,
      user: string,
      overrides?: CallOverrides
    ): Promise<void>;

    batchExecFlow(
      _data: BytesLike,
      gasLimit: BigNumberish,
      overrides?: CallOverrides
    ): Promise<void>;

    createEvaSafes(user: string, overrides?: CallOverrides): Promise<void>;

    createFlow(
      flowName: string,
      keepNetWork: BigNumberish,
      flowCode: BytesLike,
      overrides?: CallOverrides
    ): Promise<[BigNumber, string] & { _flowId: BigNumber; add: string }>;

    destroyFlow(
      _flowId: BigNumberish,
      overrides?: CallOverrides
    ): Promise<void>;

    execFlow(
      _flowId: BigNumberish,
      _inputData: BytesLike,
      overrides?: CallOverrides
    ): Promise<void>;

    getAllVaildFlowSize(overrides?: CallOverrides): Promise<BigNumber>;

    getFlowMetas(
      index: BigNumberish,
      overrides?: CallOverrides
    ): Promise<
      [number, number, string, string, string, BigNumber, BigNumber, string] & {
        flowStatus: number;
        keepNetWork: number;
        admin: string;
        lastKeeper: string;
        lastVersionflow: string;
        lastExecNumber: BigNumber;
        maxVaildBlockNumber: BigNumber;
        flowName: string;
      }
    >;

    getIndexVaildFlow(
      _index: BigNumberish,
      overrides?: CallOverrides
    ): Promise<BigNumber>;

    getSafes(user: string, overrides?: CallOverrides): Promise<string>;

    getVaildFlowRange(
      fromIndex: BigNumberish,
      endIndex: BigNumberish,
      overrides?: CallOverrides
    ): Promise<BigNumber[]>;

    pauseFlow(_flowId: BigNumberish, overrides?: CallOverrides): Promise<void>;

    startFlow(_flowId: BigNumberish, overrides?: CallOverrides): Promise<void>;

    updateFlow(
      _flowId: BigNumberish,
      _flowName: string,
      flowCode: BytesLike,
      overrides?: CallOverrides
    ): Promise<void>;

    withdrawFundByUser(
      tokenAdress: string,
      amount: BigNumberish,
      overrides?: CallOverrides
    ): Promise<void>;

    withdrawPayment(
      tokenAdress: string,
      amount: BigNumberish,
      overrides?: CallOverrides
    ): Promise<void>;
  };

  filters: {
    "FlowCreated(address,uint256,address)"(
      user?: string | null,
      _flowId?: BigNumberish | null,
      flowAdd?: null
    ): TypedEventFilter<
      [string, BigNumber, string],
      { user: string; _flowId: BigNumber; flowAdd: string }
    >;

    FlowCreated(
      user?: string | null,
      _flowId?: BigNumberish | null,
      flowAdd?: null
    ): TypedEventFilter<
      [string, BigNumber, string],
      { user: string; _flowId: BigNumber; flowAdd: string }
    >;

    "FlowDestroyed(address,uint256)"(
      user?: string | null,
      _flowId?: null
    ): TypedEventFilter<
      [string, BigNumber],
      { user: string; _flowId: BigNumber }
    >;

    FlowDestroyed(
      user?: string | null,
      _flowId?: null
    ): TypedEventFilter<
      [string, BigNumber],
      { user: string; _flowId: BigNumber }
    >;

    "FlowExecuted(address,uint256,bool,uint256,uint256,uint256)"(
      user?: string | null,
      _flowId?: null,
      sucesss?: null,
      payAmountByETH?: null,
      payAmountByFeeToken?: null,
      gasUsed?: null
    ): TypedEventFilter<
      [string, BigNumber, boolean, BigNumber, BigNumber, BigNumber],
      {
        user: string;
        _flowId: BigNumber;
        sucesss: boolean;
        payAmountByETH: BigNumber;
        payAmountByFeeToken: BigNumber;
        gasUsed: BigNumber;
      }
    >;

    FlowExecuted(
      user?: string | null,
      _flowId?: null,
      sucesss?: null,
      payAmountByETH?: null,
      payAmountByFeeToken?: null,
      gasUsed?: null
    ): TypedEventFilter<
      [string, BigNumber, boolean, BigNumber, BigNumber, BigNumber],
      {
        user: string;
        _flowId: BigNumber;
        sucesss: boolean;
        payAmountByETH: BigNumber;
        payAmountByFeeToken: BigNumber;
        gasUsed: BigNumber;
      }
    >;

    "FlowPaused(address,uint256)"(
      user?: string | null,
      _flowId?: null
    ): TypedEventFilter<
      [string, BigNumber],
      { user: string; _flowId: BigNumber }
    >;

    FlowPaused(
      user?: string | null,
      _flowId?: null
    ): TypedEventFilter<
      [string, BigNumber],
      { user: string; _flowId: BigNumber }
    >;

    "FlowStart(address,uint256)"(
      user?: string | null,
      _flowId?: null
    ): TypedEventFilter<
      [string, BigNumber],
      { user: string; _flowId: BigNumber }
    >;

    FlowStart(
      user?: string | null,
      _flowId?: null
    ): TypedEventFilter<
      [string, BigNumber],
      { user: string; _flowId: BigNumber }
    >;

    "FlowUpdated(address,uint256,address)"(
      user?: string | null,
      _flowId?: null,
      flowAdd?: null
    ): TypedEventFilter<
      [string, BigNumber, string],
      { user: string; _flowId: BigNumber; flowAdd: string }
    >;

    FlowUpdated(
      user?: string | null,
      _flowId?: null,
      flowAdd?: null
    ): TypedEventFilter<
      [string, BigNumber, string],
      { user: string; _flowId: BigNumber; flowAdd: string }
    >;

    "SetMinConfig(address,address,address,uint64,uint64,uint16,uint16)"(
      user?: string | null,
      feeRecived?: null,
      feeToken?: null,
      minGasFundForUser?: null,
      minGasFundOneFlow?: null,
      PPB?: null,
      blockCountPerTurn?: null
    ): TypedEventFilter<
      [string, string, string, BigNumber, BigNumber, number, number],
      {
        user: string;
        feeRecived: string;
        feeToken: string;
        minGasFundForUser: BigNumber;
        minGasFundOneFlow: BigNumber;
        PPB: number;
        blockCountPerTurn: number;
      }
    >;

    SetMinConfig(
      user?: string | null,
      feeRecived?: null,
      feeToken?: null,
      minGasFundForUser?: null,
      minGasFundOneFlow?: null,
      PPB?: null,
      blockCountPerTurn?: null
    ): TypedEventFilter<
      [string, string, string, BigNumber, BigNumber, number, number],
      {
        user: string;
        feeRecived: string;
        feeToken: string;
        minGasFundForUser: BigNumber;
        minGasFundOneFlow: BigNumber;
        PPB: number;
        blockCountPerTurn: number;
      }
    >;
  };

  estimateGas: {
    addFundByUser(
      tokenAdress: string,
      amount: BigNumberish,
      user: string,
      overrides?: PayableOverrides & { from?: string | Promise<string> }
    ): Promise<BigNumber>;

    batchExecFlow(
      _data: BytesLike,
      gasLimit: BigNumberish,
      overrides?: Overrides & { from?: string | Promise<string> }
    ): Promise<BigNumber>;

    createEvaSafes(
      user: string,
      overrides?: Overrides & { from?: string | Promise<string> }
    ): Promise<BigNumber>;

    createFlow(
      flowName: string,
      keepNetWork: BigNumberish,
      flowCode: BytesLike,
      overrides?: PayableOverrides & { from?: string | Promise<string> }
    ): Promise<BigNumber>;

    destroyFlow(
      _flowId: BigNumberish,
      overrides?: Overrides & { from?: string | Promise<string> }
    ): Promise<BigNumber>;

    execFlow(
      _flowId: BigNumberish,
      _inputData: BytesLike,
      overrides?: Overrides & { from?: string | Promise<string> }
    ): Promise<BigNumber>;

    getAllVaildFlowSize(overrides?: CallOverrides): Promise<BigNumber>;

    getFlowMetas(
      index: BigNumberish,
      overrides?: CallOverrides
    ): Promise<BigNumber>;

    getIndexVaildFlow(
      _index: BigNumberish,
      overrides?: CallOverrides
    ): Promise<BigNumber>;

    getSafes(user: string, overrides?: CallOverrides): Promise<BigNumber>;

    getVaildFlowRange(
      fromIndex: BigNumberish,
      endIndex: BigNumberish,
      overrides?: CallOverrides
    ): Promise<BigNumber>;

    pauseFlow(
      _flowId: BigNumberish,
      overrides?: Overrides & { from?: string | Promise<string> }
    ): Promise<BigNumber>;

    startFlow(
      _flowId: BigNumberish,
      overrides?: Overrides & { from?: string | Promise<string> }
    ): Promise<BigNumber>;

    updateFlow(
      _flowId: BigNumberish,
      _flowName: string,
      flowCode: BytesLike,
      overrides?: Overrides & { from?: string | Promise<string> }
    ): Promise<BigNumber>;

    withdrawFundByUser(
      tokenAdress: string,
      amount: BigNumberish,
      overrides?: Overrides & { from?: string | Promise<string> }
    ): Promise<BigNumber>;

    withdrawPayment(
      tokenAdress: string,
      amount: BigNumberish,
      overrides?: Overrides & { from?: string | Promise<string> }
    ): Promise<BigNumber>;
  };

  populateTransaction: {
    addFundByUser(
      tokenAdress: string,
      amount: BigNumberish,
      user: string,
      overrides?: PayableOverrides & { from?: string | Promise<string> }
    ): Promise<PopulatedTransaction>;

    batchExecFlow(
      _data: BytesLike,
      gasLimit: BigNumberish,
      overrides?: Overrides & { from?: string | Promise<string> }
    ): Promise<PopulatedTransaction>;

    createEvaSafes(
      user: string,
      overrides?: Overrides & { from?: string | Promise<string> }
    ): Promise<PopulatedTransaction>;

    createFlow(
      flowName: string,
      keepNetWork: BigNumberish,
      flowCode: BytesLike,
      overrides?: PayableOverrides & { from?: string | Promise<string> }
    ): Promise<PopulatedTransaction>;

    destroyFlow(
      _flowId: BigNumberish,
      overrides?: Overrides & { from?: string | Promise<string> }
    ): Promise<PopulatedTransaction>;

    execFlow(
      _flowId: BigNumberish,
      _inputData: BytesLike,
      overrides?: Overrides & { from?: string | Promise<string> }
    ): Promise<PopulatedTransaction>;

    getAllVaildFlowSize(
      overrides?: CallOverrides
    ): Promise<PopulatedTransaction>;

    getFlowMetas(
      index: BigNumberish,
      overrides?: CallOverrides
    ): Promise<PopulatedTransaction>;

    getIndexVaildFlow(
      _index: BigNumberish,
      overrides?: CallOverrides
    ): Promise<PopulatedTransaction>;

    getSafes(
      user: string,
      overrides?: CallOverrides
    ): Promise<PopulatedTransaction>;

    getVaildFlowRange(
      fromIndex: BigNumberish,
      endIndex: BigNumberish,
      overrides?: CallOverrides
    ): Promise<PopulatedTransaction>;

    pauseFlow(
      _flowId: BigNumberish,
      overrides?: Overrides & { from?: string | Promise<string> }
    ): Promise<PopulatedTransaction>;

    startFlow(
      _flowId: BigNumberish,
      overrides?: Overrides & { from?: string | Promise<string> }
    ): Promise<PopulatedTransaction>;

    updateFlow(
      _flowId: BigNumberish,
      _flowName: string,
      flowCode: BytesLike,
      overrides?: Overrides & { from?: string | Promise<string> }
    ): Promise<PopulatedTransaction>;

    withdrawFundByUser(
      tokenAdress: string,
      amount: BigNumberish,
      overrides?: Overrides & { from?: string | Promise<string> }
    ): Promise<PopulatedTransaction>;

    withdrawPayment(
      tokenAdress: string,
      amount: BigNumberish,
      overrides?: Overrides & { from?: string | Promise<string> }
    ): Promise<PopulatedTransaction>;
  };
}
