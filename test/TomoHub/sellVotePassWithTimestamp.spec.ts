import '@nomiclabs/hardhat-ethers';
import { expect } from 'chai';
import {
    makeSuiteCleanRoom,
    user,
    userAddress,
    userTwo,
    userTwoAddress,
    tomoHubEntryPointProxy,
    mockTomo,
    subject1,
    TOMO_NAME,
    tomorrow
} from '../__setup.spec';;
import {buildBuySeparator} from '../helpers/utils'
import { ERRORS } from '../helpers/errors';
import { ZERO_ADDRESS, BYTES32_ZERO_ADDRESS } from '../helpers/constants';
import {time} from "@nomicfoundation/hardhat-network-helpers";
import { ethers } from 'hardhat';

makeSuiteCleanRoom('Sell Whole Vote Pass With Timestamp', function () {
    context('Generic', function () {
        beforeEach(async function () {
            expect((await tomoHubEntryPointProxy._globalLockIndex())).to.equal(0);
            const sig = await buildBuySeparator(mockTomo.address, TOMO_NAME, subject1, tomoHubEntryPointProxy.address, 5);
            const price1 = await mockTomo.getBuyPriceAfterFee(subject1, 5);
            await expect(tomoHubEntryPointProxy.connect(user).buyVotePassWithLockTimeStamp(
                subject1,
                5,
                price1,
                tomorrow,
                [sig.v],
                [sig.r],
                [sig.s],
                {value: price1}
            )).to.not.be.reverted;
            expect((await tomoHubEntryPointProxy._globalLockIndex())).to.equal(1);
            expect(((await tomoHubEntryPointProxy._indexToVotePassLockInfo(0)).subject)).to.equal(subject1);
            expect(((await tomoHubEntryPointProxy._indexToVotePassLockInfo(0)).amount)).to.equal(5);
            expect(((await tomoHubEntryPointProxy._indexToVotePassLockInfo(0)).lockUntil)).to.equal(tomorrow);
            expect(((await tomoHubEntryPointProxy._indexToVotePassLockInfo(0)).owner)).to.equal(userAddress);
        })

        context('Negatives', function () {
            it('User should fail to sell lock vote pass if not the owner of lock votepass.',   async function () {
                await expect(tomoHubEntryPointProxy.connect(userTwo).sellLockVotePass(
                    0,
                    5,
                    0,
                    userTwoAddress
                )).to.be.revertedWithCustomError(tomoHubEntryPointProxy, ERRORS.NOT_LOCK_OWNER);
            });

            it('User should fail to sell lock vote pass if not reach the deadline timestamp.',   async function () {
                await expect(tomoHubEntryPointProxy.connect(user).sellLockVotePass(
                    0,
                    5,
                    0,
                    userAddress
                )).to.be.revertedWithCustomError(tomoHubEntryPointProxy, ERRORS.CANNOT_SELL_BEFORE_DEADLINE);
            });

            it('User should fail to sell lock vote pass if sell amount large than hold amount.',   async function () {
                // pass two days
                await time.increase(2 * 24 * 3600);
                await expect(tomoHubEntryPointProxy.connect(user).sellLockVotePass(
                    0,
                    6,
                    0,
                    userAddress
                )).to.be.revertedWithCustomError(tomoHubEntryPointProxy, ERRORS.VOTEPASS_NOT_ENOUGH);
            });

            it('User should fail to sell lock vote pass if sell price less than min accept price.',   async function () {
                // pass two days
                await time.increase(2 * 24 * 3600);
                const price = await mockTomo.getSellPriceAfterFee(subject1, 2);
                await expect(tomoHubEntryPointProxy.connect(user).sellLockVotePass(
                    0,
                    2,
                    price.add(10000),
                    userAddress
                )).to.be.revertedWithCustomError(tomoHubEntryPointProxy, ERRORS.LESS_THAN_MIN_ACCEPTPRICE);
            });
        })

        context('Scenarios', function () {
            it('Should get correct variable if sell part of lock vote pass with timestamp success.',   async function () {
                await time.increase(2 * 24 * 3600);
                const price = await mockTomo.getSellPriceAfterFee(subject1, 2);

                const beforeBalance = await ethers.provider.getBalance(userAddress);
                const txResp = await tomoHubEntryPointProxy.connect(user).sellLockVotePass(
                    0,
                    2,
                    price,
                    userAddress
                )
                const txReceipt = await txResp.wait();
                const gasEth =  txReceipt.gasUsed.mul(txReceipt.effectiveGasPrice);
                const afterBalance = await ethers.provider.getBalance(userAddress);
                expect((beforeBalance).sub(gasEth).add(price)).to.equal(afterBalance);

                expect(((await tomoHubEntryPointProxy._indexToVotePassLockInfo(0)).subject)).to.equal(subject1);
                expect(((await tomoHubEntryPointProxy._indexToVotePassLockInfo(0)).amount)).to.equal(3);
                expect(((await tomoHubEntryPointProxy._indexToVotePassLockInfo(0)).lockUntil)).to.equal(tomorrow);
                expect(((await tomoHubEntryPointProxy._indexToVotePassLockInfo(0)).owner)).to.equal(userAddress);
            });

            it('Should get correct variable if all lock vote pass with timestamp success.',   async function () {
                await time.increase(2 * 24 * 3600);
                const price = await mockTomo.getSellPriceAfterFee(subject1, 5);
                const beforeBalance = await ethers.provider.getBalance(userAddress);
                const txResp =  await tomoHubEntryPointProxy.connect(user).sellLockVotePass(
                    0,
                    5,
                    price,
                    userAddress
                );
                const txReceipt = await txResp.wait();
                const gasEth =  txReceipt.gasUsed.mul(txReceipt.effectiveGasPrice);
                const afterBalance = await ethers.provider.getBalance(userAddress);
                expect((beforeBalance).sub(gasEth).add(price)).to.equal(afterBalance);
                
                expect(((await tomoHubEntryPointProxy._indexToVotePassLockInfo(0)).subject)).to.equal(BYTES32_ZERO_ADDRESS);
                expect(((await tomoHubEntryPointProxy._indexToVotePassLockInfo(0)).amount)).to.equal(0);
                expect(((await tomoHubEntryPointProxy._indexToVotePassLockInfo(0)).lockUntil)).to.equal(0);
                expect(((await tomoHubEntryPointProxy._indexToVotePassLockInfo(0)).owner)).to.equal(ZERO_ADDRESS);
            });
        })
    })
})