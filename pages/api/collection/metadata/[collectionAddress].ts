import { NextApiRequest, NextApiResponse } from 'next';
import s3MetadataPlaceholder from '../../../../placeholder/starkIdFolderStarknetBucketS3.json';

export default (req: NextApiRequest, res: NextApiResponse) => {
  const { collectionAddress } = req.query;

  let s3Metadata = [{}];
  if (collectionAddress === '0x0798e884450c19e072d6620fefdbeb7387d0453d3fd51d95f5ace1f17633d88b') {
    s3Metadata = s3MetadataPlaceholder;
  }
  res.status(200).json({ s3Metadata });
}
