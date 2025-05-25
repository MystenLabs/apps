
import { KioskClient, KioskOwnerCap, KioskTransaction, Network } from "@mysten/kiosk";
import { SuiClient, getFullnodeUrl } from "@mysten/sui/client";
import { Transaction } from "@mysten/sui/transactions";
import { normalizeStructTag, parseStructTag } from "@mysten/sui/utils"

const TESTNET_ENHANCED_FRENS_PACKAGE_ID = `0x8b80449490f01439af54f0b86bc0c41cef7d3c3bb7ce81e3fd075d5d6d1b1653`
const TESTNET_SUIFREN_OUTER_TYPE = `0x80d7de9c4a56194087e0ba0bf59492aa8e6a5ee881606226930827085ddf2332::suifrens::SuiFren`;
const TESTNET_KIOSK_WITH_SUIFRENS = `0xc88725df1d71efae1d283439c81161fab7ace5fe82a5a39dcd42fb4829e10ab9`;
const TESTNET_ADDRESS_WITH_KIOSK = `0xfe09cf0b3d77678b99250572624bf74fe3b12af915c5db95f0ed5d755612eb68`;

/** Our Sui Client */
const suiClient = new SuiClient({
    url: getFullnodeUrl('testnet')
});

/** Our Kiosk Client */
const kioskClient = new KioskClient({
    client: suiClient,
    network: Network.TESTNET
})

/** Let's fetch all the owned SuiFrens inside an owned kiosk! */
const getKioskSuifrens = async (cap: KioskOwnerCap) => {
    const kiosk = await kioskClient.getKiosk({
        id: cap.kioskId,
        options: {
            withObjects: true,
            withKioskFields: true,
            objectOptions: {
                showDisplay: true,
                showType: true
            }
        }
    });

    const suifrens = kiosk.items.filter(x => x.type.startsWith(TESTNET_SUIFREN_OUTER_TYPE));
    return suifrens;
}

/** 
 * Parses the first typeParameter, as we already know the suifrens type is `SuiFren<T>`.
 * This essentially returns `T` type in a normalized string.
 */
const getSuiFrenInnerType = (type: string) => {
    return normalizeStructTag(parseStructTag(type).typeParams[0]);
}

/** 
 * An example on how we'd call the "register" function of our `enhanced_frens` contract
 * using a SuiFren we own.
 */
const exampleRegister = async () => {

    // For the sample, we'll just use a kiosk we already know has suifrens.
    // In reality, you would also look into every kiosk + find frens.
    const ownedKiosks = await kioskClient.getOwnedKiosks({
        address: TESTNET_ADDRESS_WITH_KIOSK
    });
    const kioskCapWithFrens = ownedKiosks.kioskOwnerCaps.find(x => x.kioskId === TESTNET_KIOSK_WITH_SUIFRENS);

    if (!kioskCapWithFrens) throw new Error("This kiosk is not found.");

    // find all the "suifrens" inside the kiosk.
    const frens = await getKioskSuifrens(kioskCapWithFrens);
    const selectedFren = frens[0];

    console.log("Selected fren: ", selectedFren);

    // for the sample, we assume that the first fren is the one we want to register, and is not registered!

    // We initialize a Kiosk Transaction.
    const kioskTx = new KioskTransaction({
        transaction: new Transaction(),
        kioskClient,
        cap: kioskCapWithFrens
    });

    // For any kiosk-locked object, we can get a mutable reference for it as the owner.
    // For instance, we can use our suifren to call the "register" function of the `enhanced_frens` contract.
    // You can find more actions here: https://sdk.mystenlabs.com/kiosk/kiosk-client/kiosk-transaction/managing
    kioskTx.borrowTx({
        itemType: selectedFren.type,
        itemId: selectedFren.objectId
    }, (fren) => {
        kioskTx.transaction.moveCall({
            target: `${TESTNET_ENHANCED_FRENS_PACKAGE_ID}::enhanced_frens::register`,
            arguments: [
                fren,
                kioskTx.transaction.pure.string("An awesome nickname!")
            ],
            typeArguments: [getSuiFrenInnerType(selectedFren.type)]
        });
    });

    kioskTx.finalize();

    // We set the sender to make sure dry-run works as expected!
    kioskTx.transaction.setSender(TESTNET_ADDRESS_WITH_KIOSK);

    const result = await suiClient.dryRunTransactionBlock({
        transactionBlock: await kioskTx.transaction.build({
            client: suiClient
        }),
    });

    console.dir(result, { depth: null });
}

exampleRegister();
