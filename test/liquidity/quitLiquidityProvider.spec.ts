import '@nomiclabs/hardhat-ethers';
import { expect } from 'chai';
import {
    makeSuiteCleanRoom,
    user,
    userAddress,
    tomoHubEntryPointProxy,
    mockTomo,
    subject1,
    subject,
    TOMO_NAME,
    userTwo,
    userTwoAddress,
    buyAmountForFragment,
    one_week
} from '../__setup.spec';
import {
    TomoFragmentPool__factory,
} from '../../typechain-types';
import {buildBuySeparator} from '../helpers/utils'
import { ERRORS } from '../helpers/errors';
import {time} from "@nomicfoundation/hardhat-network-helpers";
import { ethers } from 'hardhat';

makeSuiteCleanRoom('Quit from liquidity provider', function () {
    context('Generic', function () {
        beforeEach(async function () {
            const sig = await buildBuySeparator(mockTomo.address, TOMO_NAME, subject1, tomoHubEntryPointProxy.address, buyAmountForFragment);
            const price1 = await mockTomo.connect(user).getBuyPriceAfterFee(subject1, buyAmountForFragment);
            await expect(tomoHubEntryPointProxy.connect(user).buyVotePassAndFragment(
                subject1,
                buyAmountForFragment,
                1000,
                one_week,
                price1,
                [sig.v],
                [sig.r],
                [sig.s],
                {value: price1}
            )).to.not.reverted
            expect((await tomoHubEntryPointProxy._subjectToFragmentPool(subject1)).poolCreator).to.eq(userAddress);
            expect((await tomoHubEntryPointProxy._subjectToFragmentPool(subject1)).holdAmount).to.eq(buyAmountForFragment);
            expect((await tomoHubEntryPointProxy._subjectToFragmentPool(subject1)).subject).to.eq(subject1);
            const poolAddress = (await tomoHubEntryPointProxy._subjectToFragmentPool(subject1)).fragmentPoolAddress;
            const fragmentPool = TomoFragmentPool__factory.connect(poolAddress, user);
            expect(await fragmentPool._currentLiquidity()).to.eq(buyAmountForFragment * 1000);
            expect(await fragmentPool._totalSupply()).to.eq(buyAmountForFragment * 1000);
        });

        context('Negatives', function () {
            it('User should fail to quit from liquidity provider if pool not exist',   async function () {
                await expect(tomoHubEntryPointProxy.connect(user).quitFromLiquidityProvider(
                    subject
                )).to.be.revertedWithCustomError(tomoHubEntryPointProxy, ERRORS.FRAGMENT_POOL_NOT_EXIST);
            });

            it('User should fail to quit from liquidity provider if directly though pool contract.',   async function () {
                const poolAddress = (await tomoHubEntryPointProxy._subjectToFragmentPool(subject1)).fragmentPoolAddress;
                const fragmentPool = TomoFragmentPool__factory.connect(poolAddress, user);
                await expect(fragmentPool.connect(user).quitFromLiquidityProvider(
                    userAddress
                )).to.be.revertedWithCustomError(fragmentPool, ERRORS.NOT_TOMO_FRAGMENT_ENTRYPOINT);
            });

            it('User should fail to quit from liquidity provider if msg.sender is not liquidity provider.',   async function () {
                const poolAddress = (await tomoHubEntryPointProxy._subjectToFragmentPool(subject1)).fragmentPoolAddress;
                const fragmentPool = TomoFragmentPool__factory.connect(poolAddress, user);

                await expect(tomoHubEntryPointProxy.connect(userTwo).quitFromLiquidityProvider(
                    subject1
                )).to.be.revertedWithCustomError(fragmentPool, ERRORS.JUST_LIQUIDITYPROVIDER_CAN_QUIT);
            });
        })

        context('Scenarios', function () {
            it('Get correct variable when quit from liquidity providers success(no one buy fragment vote pass)',   async function () {
                await time.increase(one_week);
                const poolAddress = (await tomoHubEntryPointProxy._subjectToFragmentPool(subject1)).fragmentPoolAddress;
                const fragmentPool = TomoFragmentPool__factory.connect(poolAddress, user);
                const numVotePassAndEth = await fragmentPool.getVotePassAndEthIfQuit(userAddress);
                expect(numVotePassAndEth[0]).to.equal(2000);
                expect(numVotePassAndEth[1]).to.equal(0);

                const price = await mockTomo.getSellPriceAfterFee(subject1, buyAmountForFragment);
                const beforeBalance = await ethers.provider.getBalance(userAddress);
                const txResp =  await tomoHubEntryPointProxy.connect(user).quitFromLiquidityProvider(
                    subject1
                );
                const txReceipt = await txResp.wait();
                const gasEth =  txReceipt.gasUsed.mul(txReceipt.effectiveGasPrice);
                const afterBalance = await ethers.provider.getBalance(userAddress);
                expect((beforeBalance).sub(gasEth).add(price)).to.equal(afterBalance);

                expect(await fragmentPool._currentLiquidity()).to.eq(0);
                expect(await fragmentPool._totalSupply()).to.eq(0);
            });

            it('Get correct variable when quit from liquidity providers success(some one buy part fragment vote pass)',   async function () {
                await time.increase(one_week * 2);
                //userTwo buy 100 fragment vote pass, total 2000 liquidity 
                const poolAddress = (await tomoHubEntryPointProxy._subjectToFragmentPool(subject1)).fragmentPoolAddress;
                expect(await ethers.provider.getBalance(poolAddress)).to.equal(0);

                const fragmentPool = TomoFragmentPool__factory.connect(poolAddress, userTwo);
                const price = await fragmentPool.getBuyPriceAfterFee(100);
                await expect(tomoHubEntryPointProxy.connect(userTwo).buyFragmentVotePass(
                    subject1,
                    100,
                    price[1],
                    {value: price[1]}
                )).to.not.reverted
                expect(await fragmentPool._fragBalance(userTwoAddress)).to.equal(100);
                expect(await fragmentPool._currentLiquidity()).to.equal(buyAmountForFragment * 1000 - 100);
                const contractBalance = await ethers.provider.getBalance(poolAddress);
                expect(contractBalance).to.equal(price[1].sub(price[0].mul(200).div(10000)));
                
                //user try to quit, will sell one key to tomo, and 900 left cause eth not enough.
                const price1 = await mockTomo.getSellPriceAfterFee(subject1, 1);
                const beforeBalance = await ethers.provider.getBalance(userAddress);
                const numVotePassAndEth = await fragmentPool.getVotePassAndEthIfQuit(userAddress);
                const txResp =  await tomoHubEntryPointProxy.connect(user).quitFromLiquidityProvider(
                    subject1
                );
                const txReceipt = await txResp.wait();
                const gasEth =  txReceipt.gasUsed.mul(txReceipt.effectiveGasPrice);
                const afterBalance = await ethers.provider.getBalance(userAddress);
                // expect((beforeBalance).sub(gasEth).add(price1).add(numVotePassAndEth[1])).to.equal(afterBalance);
                expect(await fragmentPool._fragBalance(userAddress)).to.equal(900);
            });
        })
    })
})