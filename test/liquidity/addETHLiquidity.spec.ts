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

makeSuiteCleanRoom('Add Eth to liquidity', function () {
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
            expect((await tomoHubEntryPointProxy._subjectToFragmentPool(subject1)).poolCreator).to.eq(userAddress);
            expect((await tomoHubEntryPointProxy._subjectToFragmentPool(subject1)).holdAmount).to.eq(buyAmountForFragment);
            expect((await tomoHubEntryPointProxy._subjectToFragmentPool(subject1)).subject).to.eq(subject1);
            const poolAddress = (await tomoHubEntryPointProxy._subjectToFragmentPool(subject1)).fragmentPoolAddress;
            const fragmentPool = TomoFragmentPool__factory.connect(poolAddress, user);
            expect(await fragmentPool._currentLiquidity()).to.eq(buyAmountForFragment * 1000);
            expect(await fragmentPool._totalSupply()).to.eq(buyAmountForFragment * 1000);
        });

        context('Negatives', function () {
            it('User should fail to add eth to liquidity if deadline less than one week',   async function () {
                await expect(tomoHubEntryPointProxy.connect(user).addETHLiquidity(
                    subject1,
                    one_week - 1000
                )).to.be.revertedWithCustomError(tomoHubEntryPointProxy, ERRORS.DEADLINE_NEED_LARGETHAN_ONEWEEK);
            });

            it('User should fail to add eth to liquidity if msg.value equal zero',   async function () {
                await expect(tomoHubEntryPointProxy.connect(user).addETHLiquidity(
                    subject1,
                    one_week + 1000
                )).to.be.revertedWithCustomError(tomoHubEntryPointProxy, ERRORS.MSGVALUE_CANNOTBE_ZERO);
            });

            it('User should fail to add eth to liquidity if pool not exsit',   async function () {
                await expect(tomoHubEntryPointProxy.connect(user).addETHLiquidity(
                    subject,
                    one_week + 1000,
                    {value: 1000000000}
                )).to.be.revertedWithCustomError(tomoHubEntryPointProxy, ERRORS.FRAGMENT_POOL_NOT_EXIST);
            });

            it('User should fail to add eth to liquidity if directly call though pool contract address',   async function () {
                const poolAddress = (await tomoHubEntryPointProxy._subjectToFragmentPool(subject1)).fragmentPoolAddress;
                const fragmentPool = TomoFragmentPool__factory.connect(poolAddress, user);

                await expect(fragmentPool.connect(user).addETHLiquidity(
                    userAddress,
                    one_week + 1000,
                    {value: 1000000000}
                )).to.be.revertedWithCustomError(fragmentPool, ERRORS.NOT_TOMO_FRAGMENT_ENTRYPOINT);
            });

            it('User should fail to add eth to liquidity if msg.value less than one fragment key',   async function () {
                const poolAddress = (await tomoHubEntryPointProxy._subjectToFragmentPool(subject1)).fragmentPoolAddress;
                const fragmentPool = TomoFragmentPool__factory.connect(poolAddress, user);
                await expect(tomoHubEntryPointProxy.connect(user).addETHLiquidity(
                    subject1,
                    one_week + 1000,
                    {value: 1}
                )).to.be.revertedWithCustomError(fragmentPool, ERRORS.ETH_VALUE_TOO_LOW);
            });

        })

        context('Scenarios', function () {
            it('Get correct variable when add eth liquidity success',   async function () {
                
            });
        })
    })
})