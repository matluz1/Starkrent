import { NextApiRequest, NextApiResponse } from 'next';
import contractRentalPlaceholder from '../../../../placeholder/starkIdContractStarknetChain';

export default (req: NextApiRequest, res: NextApiResponse) => {
  const { collectionAddress } = req.query;

  let contractRental = [{}];
  if (collectionAddress === '0x0798e884450c19e072d6620fefdbeb7387d0453d3fd51d95f5ace1f17633d88b') {
    contractRental = contractRentalPlaceholder;
  }
  res.status(200).json({ contractRental });
}
