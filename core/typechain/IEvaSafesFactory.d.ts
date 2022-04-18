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
  CallOverrides,
} from "ethers";
import { BytesLike } from "@ethersproject/bytes";
import { Listener, Provider } from "@ethersproject/providers";
import { FunctionFragment, EventFragment, Result } from "@ethersproject/abi";
import type { TypedEventFilter, TypedEvent, TypedListener } from "./common";

interface IEvaSafesFactoryInterface extends ethers.utils.Interface {
  functions: {
    "calcSafes(address)": FunctionFragment;
    "changeConfig(address)": FunctionFragment;
    "create(address)": FunctionFragment;
    "get(address)": FunctionFragment;
  };

  encodeFunctionData(functionFragment: "calcSafes", values: [string]): string;
  encodeFunctionData(
    functionFragment: "changeConfig",
    values: [string]
  ): string;
  encodeFunctionData(functionFragment: "create", values: [string]): string;
  encodeFunctionData(functionFragment: "get", values: [string]): string;

  decodeFunctionResult(functionFragment: "calcSafes", data: BytesLike): Result;
  decodeFunctionResult(
    functionFragment: "changeConfig",
    data: BytesLike
  ): Result;
  decodeFunctionResult(functionFragment: "create", data: BytesLike): Result;
  decodeFunctionResult(functionFragment: "get", data: BytesLike): Result;

  events: {
    "WalletCreated(address,address,uint256)": EventFragment;
    "configChanged(address)": EventFragment;
  };

  getEvent(nameOrSignatureOrTopic: "WalletCreated"): EventFragment;
  getEvent(nameOrSignatureOrTopic: "configChanged"): EventFragment;
}

export type WalletCreatedEvent = TypedEvent<
  [string, string, BigNumber] & {
    user: string;
    wallet: string;
    arg2: BigNumber;
  }
>;

export type configChangedEvent = TypedEvent<[string] & { newConfig: string }>;

export class IEvaSafesFactory extends BaseContract {
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

  interface: IEvaSafesFactoryInterface;

  functions: {
    calcSafes(
      user: string,
      overrides?: CallOverrides
    ): Promise<[string] & { wallet: string }>;

    changeConfig(
      _config: string,
      overrides?: Overrides & { from?: string | Promise<string> }
    ): Promise<ContractTransaction>;

    create(
      user: string,
      overrides?: Overrides & { from?: string | Promise<string> }
    ): Promise<ContractTransaction>;

    get(
      user: string,
      overrides?: CallOverrides
    ): Promise<[string] & { wallet: string }>;
  };

  calcSafes(user: string, overrides?: CallOverrides): Promise<string>;

  changeConfig(
    _config: string,
    overrides?: Overrides & { from?: string | Promise<string> }
  ): Promise<ContractTransaction>;

  create(
    user: string,
    overrides?: Overrides & { from?: string | Promise<string> }
  ): Promise<ContractTransaction>;

  get(user: string, overrides?: CallOverrides): Promise<string>;

  callStatic: {
    calcSafes(user: string, overrides?: CallOverrides): Promise<string>;

    changeConfig(_config: string, overrides?: CallOverrides): Promise<void>;

    create(user: string, overrides?: CallOverrides): Promise<string>;

    get(user: string, overrides?: CallOverrides): Promise<string>;
  };

  filters: {
    "WalletCreated(address,address,uint256)"(
      user?: string | null,
      wallet?: null,
      undefined?: null
    ): TypedEventFilter<
      [string, string, BigNumber],
      { user: string; wallet: string; arg2: BigNumber }
    >;

    WalletCreated(
      user?: string | null,
      wallet?: null,
      undefined?: null
    ): TypedEventFilter<
      [string, string, BigNumber],
      { user: string; wallet: string; arg2: BigNumber }
    >;

    "configChanged(address)"(
      newConfig?: string | null
    ): TypedEventFilter<[string], { newConfig: string }>;

    configChanged(
      newConfig?: string | null
    ): TypedEventFilter<[string], { newConfig: string }>;
  };

  estimateGas: {
    calcSafes(user: string, overrides?: CallOverrides): Promise<BigNumber>;

    changeConfig(
      _config: string,
      overrides?: Overrides & { from?: string | Promise<string> }
    ): Promise<BigNumber>;

    create(
      user: string,
      overrides?: Overrides & { from?: string | Promise<string> }
    ): Promise<BigNumber>;

    get(user: string, overrides?: CallOverrides): Promise<BigNumber>;
  };

  populateTransaction: {
    calcSafes(
      user: string,
      overrides?: CallOverrides
    ): Promise<PopulatedTransaction>;

    changeConfig(
      _config: string,
      overrides?: Overrides & { from?: string | Promise<string> }
    ): Promise<PopulatedTransaction>;

    create(
      user: string,
      overrides?: Overrides & { from?: string | Promise<string> }
    ): Promise<PopulatedTransaction>;

    get(user: string, overrides?: CallOverrides): Promise<PopulatedTransaction>;
  };
}
