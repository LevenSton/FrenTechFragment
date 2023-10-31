import '@nomiclabs/hardhat-ethers';
import { utils } from 'ethers';
import { expect } from 'chai';
import {
    makeSuiteCleanRoom,
    user,
    deployer,
    userAddress,
    userTwo,
    governance,
    tomoHubEntryPointProxy,
    abiCoder,
    mockTomo,
    subject,
    subject1,
    buyAmount,
    buyAmount1,
    deployerAddress,
    TOMO_NAME
} from '../__setup.spec';
import {buildBuySeparator} from '../helpers/utils'
import { ERRORS } from '../helpers/errors';

makeSuiteCleanRoom('Create Tomo VotePass Pool', function () {
    context('Generic', function () {

        beforeEach(async function () {

            const sig = await buildBuySeparator(mockTomo.address, TOMO_NAME, subject, userAddress, buyAmount);
            const sig1 = await buildBuySeparator(mockTomo.address, TOMO_NAME, subject1, userAddress, buyAmount1);
            const price = await mockTomo.connect(user).getBuyPriceAfterFee(subject, buyAmount);
            const price1 = await mockTomo.connect(user).getBuyPriceAfterFee(subject1, buyAmount1);
            await expect(
                mockTomo.connect(user).buyVotePass(subject, buyAmount, [sig.v], [sig.r], [sig.s])
            ).to.be.reverted;
            await expect(
                mockTomo.connect(user).buyVotePass(subject1, buyAmount1, [sig1.v], [sig1.r], [sig1.s])
            ).to.be.reverted;

            await expect(
                mockTomo.connect(user).buyVotePass(subject, buyAmount, [sig.v], [sig.r], [sig.s], {value: price})
            ).to.not.be.reverted;
            await expect(
                mockTomo.connect(user).buyVotePass(subject1, buyAmount1, [sig1.v], [sig1.r], [sig1.s], {value: price1})
            ).to.not.be.reverted;
        });

        context('Negatives', function () {
            it('User should fail to create a fragment pool when key price less than the minPriceKeyCanFragment',   async function () {
                const sig = await buildBuySeparator(mockTomo.address, TOMO_NAME, subject, tomoHubEntryPointProxy.address, 1);
                const ethValue = utils.parseEther("2");
                await expect(tomoHubEntryPointProxy.connect(user).buyVotePassAndFragment(
                    subject,
                    1,
                    1000,
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
                    price1.sub(10000),
                    [sig.v],
                    [sig.r],
                    [sig.s],
                    {value: ethValue}
                )).to.be.revertedWithCustomError(tomoHubEntryPointProxy, ERRORS.LARGE_THAN_MAX_ACCEPTPRICE);
            });
            it('User should fail to create a fragment pool when key price large than max accept price',   async function () {
                const sig = await buildBuySeparator(mockTomo.address, TOMO_NAME, subject1, tomoHubEntryPointProxy.address, 5);
                const price1 = await mockTomo.connect(user).getBuyPriceAfterFee(subject1, 5);
                const ethValue = price1.mul(5);
                await expect(tomoHubEntryPointProxy.connect(user).buyVotePassAndFragment(
                    subject1,
                    5,
                    1000,
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
                    price1,
                    [sig.v],
                    [sig.r],
                    [sig.s],
                    {value: price1}
                )).to.be.revertedWith("Invalid signer")
            });
        })

        context('Scenarios', function () {
            it('Should return the expected pool adddress when create fragment pool success',   async function () {
                const sig = await buildBuySeparator(mockTomo.address, TOMO_NAME, subject1, tomoHubEntryPointProxy.address, 1);
                const price1 = await mockTomo.connect(user).getBuyPriceAfterFee(subject1, 1);
                //const ethValue = price1.sub(10000000);
                await expect(tomoHubEntryPointProxy.connect(user).buyVotePassAndFragment(
                    subject1,
                    1,
                    1000,
                    price1,
                    [sig.v],
                    [sig.r],
                    [sig.s],
                    {value: price1}
                )).to.not.reverted
            });
        })
    })
})