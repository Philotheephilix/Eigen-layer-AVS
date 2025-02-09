import { ethers } from "ethers";
import * as dotenv from "dotenv";
const fs = require('fs');
const path = require('path');
dotenv.config();

// Setup env variables
const provider = new ethers.JsonRpcProvider(process.env.RPC_URL);
const wallet = new ethers.Wallet(process.env.PRIVATE_KEY!, provider);
/// TODO: Hack
let chainId = 31337;

const avsDeploymentData = JSON.parse(fs.readFileSync(path.resolve(__dirname, `../contracts/deployments/hello-world/${chainId}.json`), 'utf8'));
const helloWorldServiceManagerAddress = avsDeploymentData.addresses.helloWorldServiceManager;
const helloWorldServiceManagerABI = JSON.parse(fs.readFileSync(path.resolve(__dirname, '../abis/HelloWorldServiceManager.json'), 'utf8'));
// Initialize contract objects from ABIs
const helloWorldServiceManager = new ethers.Contract(helloWorldServiceManagerAddress, helloWorldServiceManagerABI, wallet);

// Function to generate random names
function generateRandomName(): string {
    const adjectives = ['Quick', 'Lazy', 'Sleepy', 'Noisy', 'Hungry'];
    const nouns = ['Fox', 'Dog', 'Cat', 'Mouse', 'Bear'];
    const adjective = adjectives[Math.floor(Math.random() * adjectives.length)];
    const noun = nouns[Math.floor(Math.random() * nouns.length)];
    const randomName = `${adjective}${noun}${Math.floor(Math.random() * 1000)}`;
    return randomName;
}

// Flow 1: Create a new task with payment
async function createPaymentTask(amount: number, userId: string, data: string) {
    try {
        const tx = await helloWorldServiceManager.createPaymentTask(amount, userId, data);
        const receipt = await tx.wait();
        console.log(`Payment task created with hash: ${receipt.hash}`);
    } catch (error) {
        console.error('Error creating payment task:', error);
    }
}

// Flow 2: Trigger off-chain task
async function triggerOffChainTask(data: string) {
    try {
        const tx = await helloWorldServiceManager.triggerOffChainTask(data);
        const receipt = await tx.wait();
        console.log(`Off-chain task triggered with hash: ${receipt.hash}`);
    } catch (error) {
        console.error('Error triggering off-chain task:', error);
    }
}

// Flow 3: Admin withdrawal
async function requestWithdrawal(amount: number) {
    try {
        const tx = await helloWorldServiceManager.requestWithdrawal(amount);
        const receipt = await tx.wait();
        console.log(`Withdrawal requested with hash: ${receipt.hash}`);
    } catch (error) {
        console.error('Error requesting withdrawal:', error);
    }
}

// Flow 4: Send data to backend and get response
async function sendDataToBackend(data: string) {
    try {
        const tx = await helloWorldServiceManager.sendDataToBackend(data);
        const receipt = await tx.wait();
        console.log(`Data sent to backend with hash: ${receipt.hash}`);
    } catch (error) {
        console.error('Error sending data to backend:', error);
    }
}

// Function to create tasks at random intervals
function startCreatingTasks() {
    setInterval(() => {
        const randomName = generateRandomName();
        const amount = Math.floor(Math.random() * 100);
        const userId = `user${Math.floor(Math.random() * 1000)}`;
        const data = `data${Math.floor(Math.random() * 1000)}`;

        // Simulate Flow 1
        createPaymentTask(amount, userId, data);

        // Simulate Flow 2
        triggerOffChainTask(data);

        // Simulate Flow 3
        if (Math.random() < 0.1) { // 10% chance to simulate admin withdrawal
            requestWithdrawal(amount);
        }

        // Simulate Flow 4
        sendDataToBackend(data);
    }, 24000); // Create a new task every 24 seconds
}

// Start the process
startCreatingTasks();