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
    subject,
    subject1,
    TOMO_NAME,
    buyAmountForFragment
} from '../__setup.spec';
import {
    TomoFragmentPool__factory,
  } from '../../typechain-types';
import {buildBuySeparator} from '../helpers/utils'
import { ERRORS } from '../helpers/errors';
import { ethers } from 'hardhat';

makeSuiteCleanRoom('Trade Fragment Vote Pass', function () {
    context('Generic', function () {
        beforeEach(async function () {
            const sig = await buildBuySeparator(mockTomo.address, TOMO_NAME, subject1, tomoHubEntryPointProxy.address, buyAmountForFragment);
            const price1 = await mockTomo.connect(user).getBuyPriceAfterFee(subject1, buyAmountForFragment);
            await expect(tomoHubEntryPointProxy.connect(user).buyVotePassAndFragment(
                subject1,
                buyAmountForFragment,
                1000,
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
            const fragmentPool = TomoFragmentPool__factory.connect(poolAddress, userTwo);
            expect(await fragmentPool.connect(userTwo)._currentLiquidity()).to.eq(buyAmountForFragment * 1000);
            expect(await fragmentPool.connect(userTwo)._totalSupply()).to.eq(buyAmountForFragment * 1000);
        });

        context('Negatives', function () {
            it('User should fail to buy fragment vote pass if subject pool not exist.',   async function () {
                await expect(tomoHubEntryPointProxy.connect(userTwo).buyFragmentVotePass(
                    subject,
                    1,
                    100000
                )).to.be.revertedWithCustomError(tomoHubEntryPointProxy, ERRORS.FRAGMENT_POOL_NOT_EXIST);
            });

            it('User should fail to buy fragment vote pass if directly by though pool contract.',   async function () {
                const poolAddress = (await tomoHubEntryPointProxy._subjectToFragmentPool(subject1)).fragmentPoolAddress;
                const fragmentPool = TomoFragmentPool__factory.connect(poolAddress, userTwo);
                await expect(fragmentPool.connect(userTwo).buyFragmentVotePass(
                    1,
                    subject1,
                    userTwoAddress
                )).to.be.revertedWithCustomError(fragmentPool, ERRORS.NOT_TOMO_FRAGMENT_ENTRYPOINT);
            });

            it('User should fail to buy fragment vote pass if buy more than liquidity.',   async function () {
                const poolAddress = (await tomoHubEntryPointProxy._subjectToFragmentPool(subject1)).fragmentPoolAddress;
                const fragmentPool = TomoFragmentPool__factory.connect(poolAddress, userTwo);
                await expect(tomoHubEntryPointProxy.connect(userTwo).buyFragmentVotePass(
                    subject1,
                    buyAmountForFragment * 1000 + 100,
                    100000
                )).to.be.revertedWithCustomError(fragmentPool, ERRORS.LIQUIDITY_NOT_ENOUGH);
            });

            it('User should fail to buy fragment vote pass if buyer is liquidity provider.',   async function () {
                const poolAddress = (await tomoHubEntryPointProxy._subjectToFragmentPool(subject1)).fragmentPoolAddress;
                const fragmentPool = TomoFragmentPool__factory.connect(poolAddress, userTwo);
                await expect(tomoHubEntryPointProxy.connect(user).buyFragmentVotePass(
                    subject1,
                    100,
                    100000
                )).to.be.revertedWithCustomError(fragmentPool, ERRORS.LIQUIDITY_PROVIDER_CANNOT_BUY);
            });

            it('User should fail to buy fragment vote pass if buy amount large than FragmentParam.',   async function () {
                const poolAddress = (await tomoHubEntryPointProxy._subjectToFragmentPool(subject1)).fragmentPoolAddress;
                const fragmentPool = TomoFragmentPool__factory.connect(poolAddress, userTwo);
                await expect(tomoHubEntryPointProxy.connect(userTwo).buyFragmentVotePass(
                    subject1,
                    1001,
                    100000
                )).to.be.revertedWithCustomError(fragmentPool, ERRORS.CANNOT_BUY_EXCEED_FRAGMENTPARAM);
            });

            it('User should fail to buy fragment vote pass if msg.value less than price.',   async function () {
                const poolAddress = (await tomoHubEntryPointProxy._subjectToFragmentPool(subject1)).fragmentPoolAddress;
                const fragmentPool = TomoFragmentPool__factory.connect(poolAddress, userTwo);
                const price = await fragmentPool.getBuyPriceAfterFee(100);
                await expect(tomoHubEntryPointProxy.connect(userTwo).buyFragmentVotePass(
                    subject1,
                    100,
                    price[1],
                    {value: price[1].sub(100)}
                )).to.be.revertedWithCustomError(fragmentPool, ERRORS.FUNDS_NOT_ENOUGH);
            });

            it('User should fail to buy fragment vote pass if the price large than max accept price.',   async function () {
                const poolAddress = (await tomoHubEntryPointProxy._subjectToFragmentPool(subject1)).fragmentPoolAddress;
                const fragmentPool = TomoFragmentPool__factory.connect(poolAddress, userTwo);
                const price = await fragmentPool.getBuyPriceAfterFee(100);
                await expect(tomoHubEntryPointProxy.connect(userTwo).buyFragmentVotePass(
                    subject1,
                    100,
                    price[1].sub(100),
                    {value: price[1].add(100)}
                )).to.be.revertedWithCustomError(fragmentPool, ERRORS.LARGE_THAN_MAX_ACCEPTPRICE);
            });
        })

        context('Scenarios', function () {
            it('Get correct variable if buy fragment vote pass success.',   async function () {
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
                expect(await fragmentPool._currentLiquidity()).to.eq(buyAmountForFragment * 1000 - 100);
                const contractBalance = await ethers.provider.getBalance(poolAddress)
                expect(contractBalance).to.equal(price[1].sub(price[0].mul(200).div(10000)))
            });
        })
    })
})