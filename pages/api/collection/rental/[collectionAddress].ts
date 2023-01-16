import { NextApiRequest, NextApiResponse } from 'next';
import contractRentalPlaceholder from '../../../../placeholder/starkIdContractOfferStarknetChain';

export default (req: NextApiRequest, res: NextApiResponse) => {
  const { collectionAddress } = req.query;

  let contractRental = [{}];
  if (collectionAddress === '0x0783a9097b26eae0586373b2ce0ed3529ddc44069d1e0fbc4f66d42b69d6850d') {
    contractRental = contractRentalPlaceholder;
  }
  res.status(200).json({ contractRental });
}
