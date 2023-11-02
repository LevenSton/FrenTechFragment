import '@nomiclabs/hardhat-ethers';
import { expect } from 'chai';
import {
    makeSuiteCleanRoom,
    user,
    userAddress,
    userTwo,
    userTwoAddress,
    userThree,
    userThreeAddress,
    tomoHubEntryPointProxy,
    mockTomo,
    subject,
    subject1,
    TOMO_NAME,
    buyAmountForFragment,
    buyAmount1,
    one_week
} from '../__setup.spec';
import {
    TomoFragmentPool__factory,
} from '../../typechain-types';
import {buildBuySeparator} from '../helpers/utils'
import { ERRORS } from '../helpers/errors';
import { ethers } from 'hardhat';

makeSuiteCleanRoom('Sell Fragment Vote Pass', function () {
    context('Generic', function () {
        beforeEach(async function () {
            const sig = await buildBuySeparator(mockTomo.address, TOMO_NAME, subject1, tomoHubEntryPointProxy.address, buyAmountForFragment);
            const price1 = await mockTomo.connect(user).getBuyPriceAfterFee(subject1, buyAmountForFragment);
            await expect(tomoHubEntryPointProxy.connect(user).buyVotePassAndFragment(
                subject1,
                buyAmountForFragment,
                1000,
                one_week + 1000,
                price1,
                [sig.v],
                [sig.r],
                [sig.s],
                {value: price1}
            )).to.not.reverted
            expect((await tomoHubEntryPointProxy._subjectToFragmentPool(subject1)).poolCreator).to.equal(userAddress);
            expect((await tomoHubEntryPointProxy._subjectToFragmentPool(subject1)).holdAmount).to.equal(buyAmountForFragment);
            expect((await tomoHubEntryPointProxy._subjectToFragmentPool(subject1)).subject).to.equal(subject1);
            const poolAddress = (await tomoHubEntryPointProxy._subjectToFragmentPool(subject1)).fragmentPoolAddress;
            const fragmentPool = TomoFragmentPool__factory.connect(poolAddress, userTwo);
            expect(await fragmentPool.connect(userTwo)._currentLiquidity()).to.eq(buyAmountForFragment * 1000);
            const price = await fragmentPool.getBuyPriceAfterFee(100);
            await expect(tomoHubEntryPointProxy.connect(userTwo).buyFragmentVotePass(
                subject1,
                100,
                price[1],
                {value: price[1]}
            )).to.not.reverted
            expect(await fragmentPool._fragBalance(userTwoAddress)).to.equal(100);
            expect(await fragmentPool._currentLiquidity()).to.eq(buyAmountForFragment * 1000 - 100);
            const contractBalance = await ethers.provider.getBalance(poolAddress)
            expect(contractBalance).to.equal(price[1].sub(price[0].mul(200).div(10000)))

            const price2 = await fragmentPool.getBuyPriceAfterFee(200);
            await expect(tomoHubEntryPointProxy.connect(userThree).buyFragmentVotePass(
                subject1,
                200,
                price2[1],
                {value: price2[1]}
            )).to.not.reverted
            expect(await fragmentPool._fragBalance(userThreeAddress)).to.equal(200);
            expect(await fragmentPool._currentLiquidity()).to.eq(buyAmountForFragment * 1000 - 300);
            const contractBalance2 = await ethers.provider.getBalance(poolAddress)
            expect(contractBalance2.sub(contractBalance)).to.equal(price2[1].sub(price2[0].mul(200).div(10000)))
        });

        context('Negatives', function () {
            it('User should fail to sell fragment vote pass if subject pool not exist.',   async function () {
                await expect(tomoHubEntryPointProxy.connect(userTwo).sellFragmentVotePass(
                    subject,
                    100,
                    100000
                )).to.be.revertedWithCustomError(tomoHubEntryPointProxy, ERRORS.FRAGMENT_POOL_NOT_EXIST);
            });

            it('User should fail to sell whole vote pass directly though TomoHubEntryPoint contract.',   async function () {
                await expect(tomoHubEntryPointProxy.connect(userTwo).sellVotePass(
                    subject1,
                    1,
                    userTwoAddress
                )).to.be.revertedWithCustomError(tomoHubEntryPointProxy, ERRORS.CALLER_NEEDBE_FRAGMENTPOOL);
            });

            it('User should fail to sell fragment vote pass if directly by though pool contract.',   async function () {
                const poolAddress = (await tomoHubEntryPointProxy._subjectToFragmentPool(subject1)).fragmentPoolAddress;
                const fragmentPool = TomoFragmentPool__factory.connect(poolAddress, userTwo);
                await expect(fragmentPool.connect(userTwo).sellFragmentVotePass(
                    50,
                    100000,
                    userTwoAddress
                )).to.be.revertedWithCustomError(fragmentPool, ERRORS.NOT_TOMO_FRAGMENT_ENTRYPOINT);
            });

            it('User should fail to sell fragment vote pass if seller is liquidity provider.',   async function () {
                const poolAddress = (await tomoHubEntryPointProxy._subjectToFragmentPool(subject1)).fragmentPoolAddress;
                const fragmentPool = TomoFragmentPool__factory.connect(poolAddress, user);
                await expect(tomoHubEntryPointProxy.connect(user).sellFragmentVotePass(
                    subject1,
                    100,
                    100000
                )).to.be.revertedWithCustomError(fragmentPool, ERRORS.LIQUIDITY_PROVIDER_CANNOT_SELL);
            });

            it('User should fail to sell fragment vote pass if sell amount large than balance.',   async function () {
                const poolAddress = (await tomoHubEntryPointProxy._subjectToFragmentPool(subject1)).fragmentPoolAddress;
                const fragmentPool = TomoFragmentPool__factory.connect(poolAddress, userTwo);
                await expect(tomoHubEntryPointProxy.connect(userTwo).sellFragmentVotePass(
                    subject1,
                    101,
                    100000
                )).to.be.revertedWithCustomError(fragmentPool, ERRORS.NOT_ENOUGH_FRAGMENT);
            });

            it('User should fail to sell fragment vote pass if sell price less than min accecp price.',   async function () {
                const poolAddress = (await tomoHubEntryPointProxy._subjectToFragmentPool(subject1)).fragmentPoolAddress;
                const fragmentPool = TomoFragmentPool__factory.connect(poolAddress, userTwo);
                const price = await fragmentPool.getSellPriceAfterFee(50);

                await expect(tomoHubEntryPointProxy.connect(userTwo).sellFragmentVotePass(
                    subject1,
                    50,
                    price[1].add(100)
                )).to.be.revertedWithCustomError(fragmentPool, ERRORS.LESS_THAN_MIN_ACCEPTPRICE);
            });

            it('User should fail to sell fragment vote pass if eth liquidity not enough.',   async function () {
                const sig1 = await buildBuySeparator(mockTomo.address, TOMO_NAME, subject1, userAddress, buyAmount1);
                const price1 = await mockTomo.connect(user).getBuyPriceAfterFee(subject1, buyAmount1);
                await expect(
                    mockTomo.connect(user).buyVotePass(subject1, buyAmount1, [sig1.v], [sig1.r], [sig1.s], {value: price1})
                ).to.not.be.reverted;
                
                const poolAddress = (await tomoHubEntryPointProxy._subjectToFragmentPool(subject1)).fragmentPoolAddress;
                const fragmentPool = TomoFragmentPool__factory.connect(poolAddress, userThree);
                await expect(tomoHubEntryPointProxy.connect(userThree).sellFragmentVotePass(
                    subject1,
                    200,
                    0
                )).to.be.revertedWithCustomError(fragmentPool, ERRORS.ETH_LIQUIDITY_NOT_ENOUGH);
            });
        })

        context('Scenarios', function () {
            it('Get correct variable if sell fragment success.',   async function () {
                const poolAddress = (await tomoHubEntryPointProxy._subjectToFragmentPool(subject1)).fragmentPoolAddress;
                const fragmentPool = TomoFragmentPool__factory.connect(poolAddress, userTwo);
                const price = await fragmentPool.getSellPriceAfterFee(50);
                const beforeBalance = await ethers.provider.getBalance(userTwoAddress);
                const txResp = await tomoHubEntryPointProxy.connect(userTwo).sellFragmentVotePass(
                    subject1,
                    50,
                    price[1]
                )
                const txReceipt = await txResp.wait();
                const gasEth =  txReceipt.gasUsed.mul(txReceipt.effectiveGasPrice)
                expect(await fragmentPool._fragBalance(userTwoAddress)).to.equal(50);
                const afterBalance = await ethers.provider.getBalance(userTwoAddress);
                expect((beforeBalance).sub(gasEth).add(price[1])).to.equal(afterBalance);
            });
            it('Get correct variable if sell fragment amount equal fragmen param.',   async function () {
                const poolAddress = (await tomoHubEntryPointProxy._subjectToFragmentPool(subject1)).fragmentPoolAddress;
                const fragmentPool = TomoFragmentPool__factory.connect(poolAddress, userTwo);
                const price2 = await fragmentPool.getBuyPriceAfterFee(900);
                await expect(tomoHubEntryPointProxy.connect(userThree).buyFragmentVotePass(
                    subject1,
                    900,
                    price2[1],
                    {value: price2[1]}
                )).to.not.be.reverted
                expect(await fragmentPool._fragBalance(userThreeAddress)).to.equal(1100);

                const beforeAmount = (await tomoHubEntryPointProxy.connect(userThree)._subjectToFragmentPool(subject1)).holdAmount;
                const sellPrice = await mockTomo.getSellPriceAfterFee(
                    subject1,
                    1
                );
                const beforeBalance = await ethers.provider.getBalance(userThreeAddress);
                const txResp = await tomoHubEntryPointProxy.connect(userThree).sellFragmentVotePass(
                    subject1,
                    1000,
                    sellPrice
                )
                const txReceipt = await txResp.wait();
                const gasEth =  txReceipt.gasUsed.mul(txReceipt.effectiveGasPrice);
                expect(await fragmentPool._fragBalance(userThreeAddress)).to.equal(100);
                const afterAmount = (await tomoHubEntryPointProxy.connect(userThree)._subjectToFragmentPool(subject1)).holdAmount;
                expect(beforeAmount.sub(afterAmount)).to.equal(1);
                const afterBalance = await ethers.provider.getBalance(userThreeAddress);
                expect((beforeBalance).sub(gasEth).add(sellPrice)).to.equal(afterBalance);
            });
            it('Get correct variable if sell fragment amount more than fragmen param.',   async function () {
                const poolAddress = (await tomoHubEntryPointProxy._subjectToFragmentPool(subject1)).fragmentPoolAddress;
                const fragmentPool = TomoFragmentPool__factory.connect(poolAddress, userTwo);
                const price2 = await fragmentPool.getBuyPriceAfterFee(900);
                await expect(tomoHubEntryPointProxy.connect(userThree).buyFragmentVotePass(
                    subject1,
                    900,
                    price2[1],
                    {value: price2[1]}
                )).to.not.be.reverted
                expect(await fragmentPool._fragBalance(userThreeAddress)).to.equal(1100);

                const beforeAmount = (await tomoHubEntryPointProxy.connect(userThree)._subjectToFragmentPool(subject1)).holdAmount;
                const sellPrice = await mockTomo.getSellPriceAfterFee(
                    subject1,
                    1
                );
                const currentSupply = await mockTomo.getSubjectSupply(subject1);
                const keyPrice = await mockTomo.getPrice(currentSupply.sub(2), 1);
                const fragPrice = keyPrice.mul(50).div(1000);
                const fragPriceAfterFee = fragPrice.sub(fragPrice.mul(1000).div(10000));
                    
                const beforeBalance = await ethers.provider.getBalance(userThreeAddress);
                const txResp = await tomoHubEntryPointProxy.connect(userThree).sellFragmentVotePass(
                    subject1,
                    1050,
                    sellPrice
                )
                const txReceipt = await txResp.wait();
                const gasEth =  txReceipt.gasUsed.mul(txReceipt.effectiveGasPrice);
                expect(await fragmentPool._fragBalance(userThreeAddress)).to.equal(50);
                const afterAmount = (await tomoHubEntryPointProxy.connect(userThree)._subjectToFragmentPool(subject1)).holdAmount;
                expect(beforeAmount.sub(afterAmount)).to.equal(1);
                const afterBalance = await ethers.provider.getBalance(userThreeAddress);
                expect((beforeBalance).sub(gasEth).add(sellPrice).add(fragPriceAfterFee)).to.equal(afterBalance);
            });
        })
    })
})