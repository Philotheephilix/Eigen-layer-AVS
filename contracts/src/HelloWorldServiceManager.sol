// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;

import {ECDSAServiceManagerBase} from "@eigenlayer-middleware/src/unaudited/ECDSAServiceManagerBase.sol";
import {ECDSAStakeRegistry} from "@eigenlayer-middleware/src/unaudited/ECDSAStakeRegistry.sol";
import {IServiceManager} from "@eigenlayer-middleware/src/interfaces/IServiceManager.sol";
import {ECDSAUpgradeable} from "@openzeppelin-upgrades/contracts/utils/cryptography/ECDSAUpgradeable.sol";
import {IERC1271Upgradeable} from "@openzeppelin-upgrades/contracts/interfaces/IERC1271Upgradeable.sol";
import {IHelloWorldServiceManager} from "./IHelloWorldServiceManager.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "@eigenlayer/contracts/interfaces/IRewardsCoordinator.sol";
import {TransparentUpgradeableProxy} from "@openzeppelin/contracts/proxy/transparent/TransparentUpgradeableProxy.sol";

contract HelloWorldServiceManager is ECDSAServiceManagerBase, IHelloWorldServiceManager {
    using ECDSAUpgradeable for bytes32;
    // Add these events to your contract
    event OffChainDataEvent(string indexed data);
    event WithdrawalRequested(address indexed admin, uint256 amount);
    event DataResponse(string response);

    // Example function to trigger OffChainDataEvent (Flow 2)
    function triggerOffChainTask(string memory data) external {
        emit OffChainDataEvent(data);
    }

    // Example function to trigger WithdrawalRequested (Flow 3)
    function requestWithdrawal(uint256 amount) external onlyOwner {
        emit WithdrawalRequested(msg.sender, amount);
    }

    // Example function to trigger DataResponse (Flow 4)
    function submitDataResponse(string memory response) external {
        emit DataResponse(response);
    }
    
    uint32 public latestTaskNum;
    mapping(uint32 => bytes32) public allTaskHashes;
    mapping(address => mapping(uint32 => bytes)) public allTaskResponses;

    modifier onlyOperator() {
        require(ECDSAStakeRegistry(stakeRegistry).operatorRegistered(msg.sender), "Operator must be the caller");
        _;
    }

    constructor(address _avsDirectory, address _stakeRegistry, address _rewardsCoordinator, address _delegationManager)
        ECDSAServiceManagerBase(_avsDirectory, _stakeRegistry, _rewardsCoordinator, _delegationManager) {}

    function initialize(address initialOwner, address _rewardsInitiator) external initializer {
        __ServiceManagerBase_init(initialOwner, _rewardsInitiator);
    }

    function createNewTask(string memory name) external returns (Task memory) {
        Task memory newTask;
        newTask.name = name;
        newTask.taskCreatedBlock = uint32(block.number);

        allTaskHashes[latestTaskNum] = keccak256(abi.encode(newTask));
        emit NewTaskCreated(latestTaskNum, newTask);
        latestTaskNum++;

        return newTask;
    }

    function respondToTask(Task calldata task, uint32 referenceTaskIndex, bytes memory signature) external {
        require(keccak256(abi.encode(task)) == allTaskHashes[referenceTaskIndex], "Task mismatch");
        require(allTaskResponses[msg.sender][referenceTaskIndex].length == 0, "Already responded");

        bytes32 messageHash = keccak256(abi.encodePacked("Hello, ", task.name));
        bytes32 ethSignedMessageHash = messageHash.toEthSignedMessageHash();
        bytes4 magicValue = IERC1271Upgradeable.isValidSignature.selector;
        require(magicValue == ECDSAStakeRegistry(stakeRegistry).isValidSignature(ethSignedMessageHash, signature), "Invalid signature");

        allTaskResponses[msg.sender][referenceTaskIndex] = signature;
        emit TaskResponded(referenceTaskIndex, task, msg.sender);
    }
}