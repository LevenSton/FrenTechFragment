import '@nomiclabs/hardhat-ethers';
import { utils } from 'ethers';
import { expect } from 'chai';
import {
    makeSuiteCleanRoom,
    user,
    userAddress,
    tomoHubEntryPointProxy,
    mockTomo,
    subject,
    subject1,
    TOMO_NAME,
    governance,
    one_week
} from '../__setup.spec';
import {buildBuySeparator, TomoHubEntryPointState} from '../helpers/utils'
import { ERRORS } from '../helpers/errors';

makeSuiteCleanRoom('Create Tomo VotePass Pool', function () {
    context('Generic', function () {

        context('Negatives', function () {
            it('User should fail to create a fragment pool when deadline less than one week',   async function () {
                const sig = await buildBuySeparator(mockTomo.address, TOMO_NAME, subject1, tomoHubEntryPointProxy.address, 1);
                const price1 = await mockTomo.connect(user).getBuyPriceAfterFee(subject1, 1);
                await expect(tomoHubEntryPointProxy.connect(user).buyVotePassAndFragment(
                    subject1,
                    1,
                    1000,
                    one_week-1000,
                    price1,
                    [sig.v],
                    [sig.r],
                    [sig.s],
                    {value: price1}
                )).to.be.revertedWithCustomError(tomoHubEntryPointProxy, ERRORS.DEADLINE_NEED_LARGETHAN_ONEWEEK);
            });

            it('User should fail to create a fragment pool when key price less than the minPriceKeyCanFragment',   async function () {
                const sig = await buildBuySeparator(mockTomo.address, TOMO_NAME, subject, tomoHubEntryPointProxy.address, 1);
                const ethValue = utils.parseEther("2");
                await expect(tomoHubEntryPointProxy.connect(user).buyVotePassAndFragment(
                    subject,
                    1,
                    1000,
                    one_week + 1000,
                    100000,
                    [sig.v],
                    [sig.r],
                    [sig.s],
                    {value: ethValue}
                )).to.be.revertedWithCustomError(tomoHubEntryPointProxy, ERRORS.KEYPRICE_TOOLOW_CANNOT_FRAGMENT);
            });
            it('User should fail to create a fragment pool when msg.value less than the key price',   async function () {
                const sig = await buildBuySeparator(mockTomo.address, TOMO_NAME, subject1, tomoHubEntryPointProxy.address, 1);
                const price1 = await mockTomo.connect(user).getBuyPriceAfterFee(subject1, 1);
                const ethValue = price1.sub(10000000);
                await expect(tomoHubEntryPointProxy.connect(user).buyVotePassAndFragment(
                    subject1,
                    1,
                    1000,
                    one_week + 1000,
                    100000,
                    [sig.v],
                    [sig.r],
                    [sig.s],
                    {value: ethValue}
                )).to.be.revertedWithCustomError(tomoHubEntryPointProxy, ERRORS.FUNDS_NOT_ENOUGH);
            });
            it('User should fail to create a fragment pool when key price large than max accept price',   async function () {
                const sig = await buildBuySeparator(mockTomo.address, TOMO_NAME, subject1, tomoHubEntryPointProxy.address, 5);
                const price1 = await mockTomo.connect(user).getBuyPriceAfterFee(subject1, 5);
                const ethValue = price1.mul(5);
                await expect(tomoHubEntryPointProxy.connect(user).buyVotePassAndFragment(
                    subject1,
                    5,
                    1000,
                    one_week + 1000,
                    price1.sub(10000),
                    [sig.v],
                    [sig.r],
                    [sig.s],
                    {value: ethValue}
                )).to.be.revertedWithCustomError(tomoHubEntryPointProxy, ERRORS.LARGE_THAN_MAX_ACCEPTPRICE);
            });
            it('failed to create fragment pool if use error address to sign',   async function () {
                const sig = await buildBuySeparator(mockTomo.address, TOMO_NAME, subject1, userAddress, 1);
                const price1 = await mockTomo.connect(user).getBuyPriceAfterFee(subject1, 1);
                await expect(tomoHubEntryPointProxy.connect(user).buyVotePassAndFragment(
                    subject1,
                    1,
                    1000,
                    one_week + 1000,
                    price1,
                    [sig.v],
                    [sig.r],
                    [sig.s],
                    {value: price1}
                )).to.be.revertedWith("Invalid signer")
            });
            it('Should failed if pause the contract',   async function () {
                await expect(tomoHubEntryPointProxy.connect(governance).setState(TomoHubEntryPointState.Paused)).to.not.be.reverted;
                const sig = await buildBuySeparator(mockTomo.address, TOMO_NAME, subject1, tomoHubEntryPointProxy.address, 1);
                const price1 = await mockTomo.connect(user).getBuyPriceAfterFee(subject1, 1);
                await expect(tomoHubEntryPointProxy.connect(user).buyVotePassAndFragment(
                    subject1,
                    1,
                    1000,
                    one_week + 1000,
                    price1,
                    [sig.v],
                    [sig.r],
                    [sig.s],
                    {value: price1}
                )).to.be.revertedWithCustomError(tomoHubEntryPointProxy, ERRORS.PAUSED);
            });
        })

        context('Scenarios', function () {
            it('Get correct variable when create fragment pool success',   async function () {
                const sig = await buildBuySeparator(mockTomo.address, TOMO_NAME, subject1, tomoHubEntryPointProxy.address, 1);
                const price1 = await mockTomo.connect(user).getBuyPriceAfterFee(subject1, 1);
                //const ethValue = price1.sub(10000000);
                await expect(tomoHubEntryPointProxy.connect(user).buyVotePassAndFragment(
                    subject1,
                    1,
                    1000,
                    one_week + 1000,
                    price1,
                    [sig.v],
                    [sig.r],
                    [sig.s],
                    {value: price1}
                )).to.not.reverted
                expect((await tomoHubEntryPointProxy._subjectToFragmentPool(subject1)).poolCreator).to.equal(userAddress);
                expect((await tomoHubEntryPointProxy._subjectToFragmentPool(subject1)).holdAmount).to.equal(1);
                expect((await tomoHubEntryPointProxy._subjectToFragmentPool(subject1)).subject).to.equal(subject1);
            });
        })
    })
})