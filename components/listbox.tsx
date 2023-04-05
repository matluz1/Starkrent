import Image from 'next/image';
import { Listbox } from '@headlessui/react';
import { Dispatch } from 'react';
import styles from '../styles/Listbox.module.scss';

interface Category {
  id: number,
  name: string,
  unavailable: boolean
}

interface MyListboxProps {
  categories: Category[],
  selectedCategory: Category,
  setSelectedCategory: Dispatch<Category>
}
export default function MyListbox({categories, selectedCategory, setSelectedCategory} : MyListboxProps) {

  return (
    <Listbox value={selectedCategory} onChange={setSelectedCategory}>
      <div className={styles.listboxWrapper}>
        <Listbox.Button className={styles.listboxButton}>
          <span>{selectedCategory.name}</span>
          <Image
              src="/chevron.svg"
              alt="Listbox arrow"
              width={12}
              height={12}
            />
        </Listbox.Button>
        <Listbox.Options className={styles.listboxOptions}>
          {categories.map((category) => (
            <Listbox.Option
              key={category.id}
              value={category}
              disabled={category.unavailable}
            >
              {category.name}
            </Listbox.Option>
          ))}
        </Listbox.Options>
      </div>
    </Listbox>
  )
}
